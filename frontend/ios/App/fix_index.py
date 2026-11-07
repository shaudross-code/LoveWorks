import re

with open('App/public/index.html', 'r') as file:
    content = file.read()

inject = """<script>
window.onerror = function(msg, url, line, col, error) {
   alert("Error: " + msg + "\nurl: " + url + "\nline: " + line);
   console.log("Error: " + msg + "\nurl: " + url + "\nline: " + line);
   return false;
};
window.onunhandledrejection = function(event) {
   alert("Promise Reject: " + event.reason);
   console.log("Promise Reject: " + event.reason);
};
</script>"""

content = content.replace("<title>iLoveWorks", inject + "<title>iLoveWorks")

with open('App/public/index.html', 'w') as file:
    file.write(content)
