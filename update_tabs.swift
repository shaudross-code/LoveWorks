import Foundation

let path = "iLoveWorks/WorkerDashboardView.swift"
var content = try! String(contentsOfFile: path, encoding: .utf8)
content = content.replacingOccurrences(of: """
            WorkerDashboardMainView(viewModel: viewModel)
                .tabItem { Label("Workday", systemImage: "bolt.heart.fill") }

            WorkerEssentialsView(viewModel: viewModel)
                .tabItem { Label("Essentials", systemImage: "cart.fill") }

            WorkerTripsView(viewModel: viewModel)
                .tabItem { Label("Trips", systemImage: "airplane") }

            MySizesView()
                .tabItem { Label("My Sizes", systemImage: "ruler.fill") }
""", with: """
            WorkerDashboardMainView(viewModel: viewModel)
                .tabItem { Label("Workday", systemImage: "clock.fill") }

            Text("History Placeholder")  // Port needed
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }

            WorkerTripsView(viewModel: viewModel)
                .tabItem { Label("Trips", systemImage: "airplane") }

            WorkerEssentialsView(viewModel: viewModel)
                .tabItem { Label("Essentials", systemImage: "briefcase.fill") }

            WorkerAwardsView(viewModel: viewModel)
                .tabItem { Label("Awards", systemImage: "trophy.fill") }

            Text("What's new Placeholder")
                .tabItem { Label("What's new", systemImage: "megaphone.fill") }

            MySizesView()
                .tabItem { Label("My Sizes", systemImage: "ruler.fill") }

            Text("Profile Placeholder")
                .tabItem { Label("Profile", systemImage: "person.crop.circle.fill") }
""")

try! content.write(toFile: path, atomically: true, encoding: .utf8)
