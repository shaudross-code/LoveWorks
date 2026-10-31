export const GUIDE = [
  { k: "height", title: "Height", img: "/measure/height.webp",
    tip: "Stand barefoot with your heels against a wall, looking straight ahead. Mark the top of your head and measure down to the floor." },
  { k: "neck", title: "Neck", img: "/measure/neck.webp",
    tip: "Wrap the tape around the base of your neck, just above the collarbone where a shirt collar sits. Slip one finger under the tape for comfort." },
  { k: "shoulder", title: "Shoulder width", img: "/measure/shoulder.webp",
    tip: "Across the top of your back, from the bony tip of one shoulder to the other. Easiest with a helper." },
  { k: "chest", title: "Chest / bust", img: "/measure/chest.webp",
    tip: "Around the fullest part of your chest, under the arms and across the shoulder blades. Keep the tape level and breathe normally." },
  { k: "waist", title: "Waist", img: "/measure/waist.webp",
    tip: "Around your natural waist — the narrowest part of your torso, just above the navel. Don't suck in." },
  { k: "hips", title: "Hips", img: "/measure/hips.webp",
    tip: "Feet together, tape around the fullest part of your hips and seat, parallel to the floor." },
  { k: "sleeve", title: "Sleeve length", img: "/measure/sleeve.webp",
    tip: "From the centre back of your neck, over the point of the shoulder, down a slightly bent arm to the wrist bone." },
  { k: "inseam", title: "Inseam", img: "/measure/inseam.webp",
    tip: "Along the inside of your leg from the crotch straight down to the ankle bone, or where you want trousers to end." },
  { k: "head", title: "Head circumference", img: "/measure/head.webp",
    tip: "Around your head just above the eyebrows and the tops of your ears — the widest part. Used for hats and hard hats." },
  { k: "hand", title: "Hand circumference", img: "/measure/hand.webp",
    tip: "Around the widest part of your dominant hand across the knuckles, with the thumb left out. Used for glove sizing." },
];

export const GUIDE_KEYS = new Set(GUIDE.map((g) => g.k));
export const guideIndex = (k) => GUIDE.findIndex((g) => g.k === k);
