import re

with open("iLoveWorks/AdminDashboardView.swift", "r") as f:
    text = f.read()

# Fix layout appearance and sizes styling

# PageHeader replacement
old_ph = """struct PageHeader: View {
    let eyebrow: String
    let title: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(eyebrow)
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(Theme.lovePink)
                .tracking(1.5)
            Text(title)
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(Theme.textMain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}"""

new_ph = """struct PageHeader: View {
    let eyebrow: String
    let title: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(eyebrow)
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(Theme.lovePink)
                .tracking(1.5)
            Text(title)
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(Theme.textMain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.top, 20)
    }
}"""
text = text.replace(old_ph, new_ph)

# Crew Live inline header replacement (use PageHeader and fix visual)
old_crew = """                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("CREW · LIVE")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundStyle(Theme.lovePink)
                                    .tracking(1.5)
                                Text("Your workers.")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundStyle(Theme.textMain)
                            }
                            Spacer()
                            Button(action: { showingAddWorker = true }) {
                                Image(systemName: "person.badge.plus.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(Theme.lovePink)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)"""

new_crew = """                        HStack {
                            PageHeader(eyebrow: "CREW · LIVE", title: "Your workers.")
                                .padding(.horizontal, 0)
                                .padding(.top, 0)
                            Spacer()
                            Button(action: { showingAddWorker = true }) {
                                Image(systemName: "person.badge.plus.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(Theme.lovePink)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)"""

text = text.replace(old_crew, new_crew)


# Appearance in EditWorkerModal
old_ewm = """                        Image(systemName: "person.crop.circle.badge.xmark")
                            .font(.system(size: 64))
                            .foregroundStyle(.red)
                            .padding(.top, 40)
                            
                        Text(worker.name)
                            .font(.title)
                            .foregroundStyle(Theme.textMain)
                            .bold()
                            
                        Text(worker.email)
                            .foregroundStyle(Theme.textMuted)"""

new_ewm = """                        if let urlString = worker.avatarUrl, let url = URL(string: APIClient.shared.fullURL(for: urlString)) {
                            AsyncImage(url: url) { image in
                                image.resizable().aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Circle().fill(Theme.secondary)
                            }
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                            .padding(.top, 40)
                        } else {
                            Circle()
                                .fill(Theme.secondary)
                                .frame(width: 80, height: 80)
                                .overlay(Text(String(worker.name.prefix(1))).font(.title).bold())
                                .padding(.top, 40)
                        }
                            
                        Text(worker.name)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(Theme.textMain)
                            
                        Text(worker.email)
                            .font(.system(size: 16))
                            .foregroundStyle(Theme.textMuted)
                            .padding(.bottom, 20)"""
text = text.replace(old_ewm, new_ewm)


with open("iLoveWorks/AdminDashboardView.swift", "w") as f:
    f.write(text)

print("Applied cosmetic layout updates")
