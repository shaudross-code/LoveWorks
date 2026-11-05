import Foundation

struct MeasureGuideItem: Identifiable {
    let key: String
    let title: String
    let tip: String
    var id: String { key }
    var imageName: String { "measure_\(key)" }
}

enum MeasureGuide {
    static let items: [MeasureGuideItem] = [
        .init(key: "height", title: "Height", tip: "Stand barefoot with your heels against a wall, looking straight ahead. Mark the top of your head and measure down to the floor."),
        .init(key: "neck", title: "Neck", tip: "Wrap the tape around the base of your neck, just above the collarbone where a shirt collar sits. Slip one finger under the tape for comfort."),
        .init(key: "shoulder", title: "Shoulder width", tip: "Across the top of your back, from the bony tip of one shoulder to the other. Easiest with a helper."),
        .init(key: "chest", title: "Chest / bust", tip: "Around the fullest part of your chest, under the arms and across the shoulder blades. Keep the tape level and breathe normally."),
        .init(key: "waist", title: "Waist", tip: "Around your natural waist — the narrowest part of your torso, just above the navel. Don't suck in."),
        .init(key: "hips", title: "Hips", tip: "Feet together, tape around the fullest part of your hips and seat, parallel to the floor."),
        .init(key: "sleeve", title: "Sleeve length", tip: "From the centre back of your neck, over the point of the shoulder, down a slightly bent arm to the wrist bone."),
        .init(key: "inseam", title: "Inseam", tip: "Along the inside of your leg from the crotch straight down to the ankle bone, or where you want trousers to end."),
        .init(key: "head", title: "Head circumference", tip: "Around your head just above the eyebrows and the tops of your ears — the widest part. Used for hats and hard hats."),
        .init(key: "hand", title: "Hand circumference", tip: "Around the widest part of your dominant hand across the knuckles, with the thumb left out. Used for glove sizing."),
    ]

    static let keys = Set(items.map(\.key))

    static func index(of key: String) -> Int { items.firstIndex { $0.key == key } ?? 0 }
}
