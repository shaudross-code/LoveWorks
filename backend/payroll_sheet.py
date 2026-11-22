"""Google Sheets client for the payroll record (through the admin's Emergent Google Sheets connection)."""
import os
import time
from datetime import datetime
from urllib.parse import quote

import httpx

SHEETS = "https://sheets.googleapis.com/v4/spreadsheets"
WEEKS_TAB = "Paid weeks"
DAYS_TAB = "Daily detail"
WEEKS_HEADER = ["Week start", "Week end", "Worker", "Email", "Tasks", "Hours", "Amount", "Paid on", "Paid by", "Note", "Payout ID"]
DAYS_HEADER = ["Week start", "Worker", "Email", "Date", "Day", "Tasks", "Hours", "Pay", "Tasks done", "Payout ID"]

_token: tuple[str, float] = ("", 0.0)


class SheetError(Exception):
    pass


def connection_id() -> str:
    return (os.environ.get("GOOGLE_SHEETS_CONNECTION_ID") or "").strip()


def configured() -> bool:
    return bool(connection_id() and os.environ.get("EMERGENT_LLM_KEY"))


async def _access_token(fresh: bool = False) -> str:
    global _token
    token, expires = _token
    if token and not fresh and time.time() < expires - 60:
        return token
    base = (os.environ.get("INTEGRATION_PROXY_URL") or "").strip() or "https://integrations.emergentagent.com"
    async with httpx.AsyncClient(timeout=15) as client:
        r = await client.post(base.rstrip("/") + "/connectors/v2/access-token",
                              headers={"Authorization": f"Bearer {os.environ['EMERGENT_LLM_KEY']}"},
                              json={"connection_id": connection_id()})
    body = r.json()
    if r.status_code != 200:
        code = body.get("code", "provider_error")
        hint = " Reconnect Google Sheets in the Emergent chat." if code in ("connection_expired", "connection_not_found") else ""
        raise SheetError(f"Google Sheets: {body.get('message', r.text)}{hint}")
    try:
        exp = datetime.fromisoformat(body["expires_at"].replace("Z", "+00:00")).timestamp()
    except (KeyError, AttributeError, ValueError):
        exp = time.time() + 300
    _token = (body["access_token"], exp)
    return body["access_token"]


async def _call(method: str, url: str, **kwargs) -> dict:
    for fresh in (False, True):
        token = await _access_token(fresh)
        async with httpx.AsyncClient(timeout=30) as client:
            r = await client.request(method, url, headers={"Authorization": f"Bearer {token}"}, **kwargs)
        if r.status_code != 401:
            break
    if r.status_code >= 400:
        try:
            msg = r.json()["error"]["message"]
        except Exception:
            msg = r.text[:200]
        raise SheetError(f"Google Sheets {r.status_code}: {msg}")
    return r.json() if r.content else {}


def _range(tab: str, cells: str) -> str:
    return quote(f"'{tab}'!{cells}", safe="")


async def create_spreadsheet(title: str) -> dict:
    tab = lambda name: {"properties": {"title": name, "gridProperties": {"frozenRowCount": 1}}}  # noqa: E731
    made = await _call("POST", SHEETS, json={"properties": {"title": title}, "sheets": [tab(WEEKS_TAB), tab(DAYS_TAB)]})
    sid = made["spreadsheetId"]
    await _call("POST", f"{SHEETS}/{sid}/values:batchUpdate", json={"valueInputOption": "RAW", "data": [
        {"range": f"'{WEEKS_TAB}'!A1", "values": [WEEKS_HEADER]},
        {"range": f"'{DAYS_TAB}'!A1", "values": [DAYS_HEADER]},
    ]})
    await format_sheet(sid)
    return {"spreadsheet_id": sid, "url": made.get("spreadsheetUrl") or f"https://docs.google.com/spreadsheets/d/{sid}/edit"}


async def format_sheet(sid: str) -> None:
    """Bold headers and show the pay columns as dollars."""
    meta = await _call("GET", f"{SHEETS}/{sid}", params={"fields": "sheets.properties(sheetId,title)"})
    gids = {s["properties"]["title"]: s["properties"]["sheetId"] for s in meta.get("sheets", [])}
    money = {"numberFormat": {"type": "CURRENCY", "pattern": "$#,##0.00"}}
    requests = []
    for tab, col in ((WEEKS_TAB, 6), (DAYS_TAB, 7)):
        if tab not in gids:
            continue
        requests.append({"repeatCell": {"range": {"sheetId": gids[tab], "startRowIndex": 0, "endRowIndex": 1},
                                        "cell": {"userEnteredFormat": {"textFormat": {"bold": True}}},
                                        "fields": "userEnteredFormat.textFormat.bold"}})
        requests.append({"repeatCell": {"range": {"sheetId": gids[tab], "startRowIndex": 1, "startColumnIndex": col, "endColumnIndex": col + 1},
                                        "cell": {"userEnteredFormat": money}, "fields": "userEnteredFormat.numberFormat"}})
    if requests:
        await _call("POST", f"{SHEETS}/{sid}:batchUpdate", json={"requests": requests})


async def append(sid: str, tab: str, rows: list) -> None:
    if rows:
        await _call("POST", f"{SHEETS}/{sid}/values/{_range(tab, 'A1')}:append",
                    params={"valueInputOption": "USER_ENTERED", "insertDataOption": "OVERWRITE"}, json={"values": rows})


async def delete_payout_rows(sid: str, payout_id: str) -> int:
    """Deletes every row whose Payout ID column matches, in both tabs. Returns rows removed."""
    meta = await _call("GET", f"{SHEETS}/{sid}", params={"fields": "sheets.properties(sheetId,title)"})
    gids = {s["properties"]["title"]: s["properties"]["sheetId"] for s in meta.get("sheets", [])}
    requests = []
    for tab, col in ((WEEKS_TAB, "K"), (DAYS_TAB, "J")):
        if tab not in gids:
            continue
        values = (await _call("GET", f"{SHEETS}/{sid}/values/{_range(tab, f'{col}1:{col}')}")).get("values", [])
        hits = [i for i, row in enumerate(values) if row and row[0] == payout_id]
        requests += [{"deleteDimension": {"range": {"sheetId": gids[tab], "dimension": "ROWS", "startIndex": i, "endIndex": i + 1}}}
                     for i in sorted(hits, reverse=True)]
    if requests:
        await _call("POST", f"{SHEETS}/{sid}:batchUpdate", json={"requests": requests})
    return len(requests)
