import CoreGraphics

/// Source wheel masks in the original 1536 x 1024 artwork coordinate system.
/// Keeping the forks, calipers, exhaust and hubs stationary preserves every rider's bike.
struct RotorArtwork {
    let radius: CGFloat
    let hub: CGFloat
    let sectorStart: CGFloat
    let sectors: Int
    let hardware: [[CGPoint]]

    static let riders: [String: [RotorArtwork]] = [
        "shiba": [
            .init(radius: 155, hub: 32, sectorStart: 90, sectors: 4, hardware: [[CGPoint(x: 230, y: 564), CGPoint(x: 333, y: 568), CGPoint(x: 534, y: 744), CGPoint(x: 477, y: 849), CGPoint(x: 332, y: 758), CGPoint(x: 250, y: 721)], [CGPoint(x: 237, y: 708), CGPoint(x: 298, y: 690), CGPoint(x: 446, y: 650), CGPoint(x: 476, y: 728), CGPoint(x: 301, y: 776), CGPoint(x: 238, y: 773)], [CGPoint(x: 286, y: 776), CGPoint(x: 475, y: 755), CGPoint(x: 479, y: 799), CGPoint(x: 316, y: 823)]]),
            .init(radius: 157, hub: 31, sectorStart: 0, sectors: 4, hardware: [[CGPoint(x: 1173, y: 569), CGPoint(x: 1237, y: 565), CGPoint(x: 1301, y: 764), CGPoint(x: 1274, y: 801), CGPoint(x: 1233, y: 799)], [CGPoint(x: 1135, y: 683), CGPoint(x: 1195, y: 691), CGPoint(x: 1234, y: 770), CGPoint(x: 1205, y: 815), CGPoint(x: 1120, y: 803), CGPoint(x: 1120, y: 747)], [CGPoint(x: 1198, y: 617), CGPoint(x: 1284, y: 592), CGPoint(x: 1343, y: 604), CGPoint(x: 1292, y: 649), CGPoint(x: 1294, y: 758), CGPoint(x: 1275, y: 777), CGPoint(x: 1244, y: 735)]]),
        ],
        "eagle": [
            .init(radius: 132, hub: 43, sectorStart: 210, sectors: 6, hardware: [[CGPoint(x: 106, y: 763), CGPoint(x: 467, y: 770), CGPoint(x: 477, y: 826), CGPoint(x: 109, y: 821)], [CGPoint(x: 216, y: 823), CGPoint(x: 470, y: 825), CGPoint(x: 472, y: 883), CGPoint(x: 215, y: 879)], [CGPoint(x: 224, y: 763), CGPoint(x: 464, y: 658), CGPoint(x: 471, y: 685), CGPoint(x: 276, y: 784)]]),
            .init(radius: 138, hub: 32, sectorStart: 0, sectors: 4, hardware: [[CGPoint(x: 1171, y: 621), CGPoint(x: 1220, y: 597), CGPoint(x: 1340, y: 783), CGPoint(x: 1341, y: 811), CGPoint(x: 1301, y: 829), CGPoint(x: 1264, y: 789)], [CGPoint(x: 1222, y: 727), CGPoint(x: 1269, y: 739), CGPoint(x: 1281, y: 779), CGPoint(x: 1257, y: 811), CGPoint(x: 1208, y: 805)], [CGPoint(x: 1158, y: 664), CGPoint(x: 1197, y: 673), CGPoint(x: 1172, y: 788), CGPoint(x: 1164, y: 832), CGPoint(x: 1120, y: 855)]]),
        ],
        "tiger": [
            .init(radius: 142, hub: 28, sectorStart: 90, sectors: 4, hardware: [[CGPoint(x: 249, y: 755), CGPoint(x: 465, y: 709), CGPoint(x: 478, y: 759), CGPoint(x: 286, y: 803), CGPoint(x: 252, y: 798)], [CGPoint(x: 299, y: 704), CGPoint(x: 343, y: 700), CGPoint(x: 354, y: 741), CGPoint(x: 313, y: 758)], [CGPoint(x: 286, y: 692), CGPoint(x: 474, y: 683), CGPoint(x: 479, y: 699), CGPoint(x: 285, y: 706)], [CGPoint(x: 325, y: 804), CGPoint(x: 477, y: 792), CGPoint(x: 479, y: 810), CGPoint(x: 326, y: 820)]]),
            .init(radius: 146, hub: 28, sectorStart: 0, sectors: 4, hardware: [[CGPoint(x: 1104, y: 592), CGPoint(x: 1146, y: 581), CGPoint(x: 1221, y: 745), CGPoint(x: 1246, y: 767), CGPoint(x: 1234, y: 797), CGPoint(x: 1181, y: 797), CGPoint(x: 1158, y: 746)], [CGPoint(x: 1131, y: 746), CGPoint(x: 1186, y: 742), CGPoint(x: 1202, y: 783), CGPoint(x: 1182, y: 817), CGPoint(x: 1123, y: 816)]]),
        ],
        "polar": [
            .init(radius: 136, hub: 31, sectorStart: 90, sectors: 4, hardware: [[CGPoint(x: 279, y: 773), CGPoint(x: 479, y: 724), CGPoint(x: 481, y: 790), CGPoint(x: 313, y: 832), CGPoint(x: 277, y: 827)], [CGPoint(x: 302, y: 721), CGPoint(x: 346, y: 711), CGPoint(x: 374, y: 747), CGPoint(x: 347, y: 777), CGPoint(x: 306, y: 769)], [CGPoint(x: 333, y: 832), CGPoint(x: 481, y: 809), CGPoint(x: 483, y: 825), CGPoint(x: 337, y: 849)]]),
            .init(radius: 140, hub: 31, sectorStart: 0, sectors: 4, hardware: [[CGPoint(x: 1106, y: 626), CGPoint(x: 1151, y: 614), CGPoint(x: 1213, y: 753), CGPoint(x: 1234, y: 781), CGPoint(x: 1210, y: 805), CGPoint(x: 1180, y: 802)], [CGPoint(x: 1129, y: 775), CGPoint(x: 1178, y: 770), CGPoint(x: 1200, y: 815), CGPoint(x: 1180, y: 839), CGPoint(x: 1132, y: 837)]]),
        ],
        "flamingo": [
            .init(radius: 84, hub: 49, sectorStart: 105, sectors: 6, hardware: [[CGPoint(x: 288, y: 801), CGPoint(x: 479, y: 811), CGPoint(x: 514, y: 849), CGPoint(x: 493, y: 889), CGPoint(x: 381, y: 899), CGPoint(x: 304, y: 880)], [CGPoint(x: 244, y: 783), CGPoint(x: 447, y: 783), CGPoint(x: 447, y: 808), CGPoint(x: 244, y: 808)]]),
            .init(radius: 83, hub: 45, sectorStart: 0, sectors: 4, hardware: [[CGPoint(x: 1160, y: 742), CGPoint(x: 1195, y: 746), CGPoint(x: 1236, y: 850), CGPoint(x: 1228, y: 876), CGPoint(x: 1202, y: 869), CGPoint(x: 1183, y: 825)]]),
        ],
        "toucan": [
            .init(radius: 143, hub: 51, sectorStart: 90, sectors: 4, hardware: [[CGPoint(x: 446, y: 570), CGPoint(x: 484, y: 576), CGPoint(x: 398, y: 775), CGPoint(x: 363, y: 789), CGPoint(x: 355, y: 762)], [CGPoint(x: 359, y: 749), CGPoint(x: 655, y: 752), CGPoint(x: 669, y: 802), CGPoint(x: 554, y: 814), CGPoint(x: 361, y: 793)], [CGPoint(x: 350, y: 757), CGPoint(x: 584, y: 789), CGPoint(x: 603, y: 838), CGPoint(x: 571, y: 859), CGPoint(x: 350, y: 821)]]),
            .init(radius: 145, hub: 57, sectorStart: 0, sectors: 4, hardware: [[CGPoint(x: 1100, y: 626), CGPoint(x: 1145, y: 624), CGPoint(x: 1235, y: 782), CGPoint(x: 1227, y: 808), CGPoint(x: 1203, y: 805), CGPoint(x: 1164, y: 733)]]),
        ],
        "raccoon": [
            .init(radius: 143, hub: 38, sectorStart: 90, sectors: 4, hardware: [[CGPoint(x: 361, y: 594), CGPoint(x: 407, y: 606), CGPoint(x: 335, y: 742), CGPoint(x: 299, y: 759), CGPoint(x: 296, y: 731)], [CGPoint(x: 253, y: 751), CGPoint(x: 574, y: 725), CGPoint(x: 592, y: 766), CGPoint(x: 298, y: 794), CGPoint(x: 252, y: 790)], [CGPoint(x: 312, y: 699), CGPoint(x: 575, y: 697), CGPoint(x: 576, y: 717), CGPoint(x: 310, y: 718)], [CGPoint(x: 339, y: 788), CGPoint(x: 575, y: 780), CGPoint(x: 577, y: 804), CGPoint(x: 333, y: 814)]]),
            .init(radius: 143, hub: 42, sectorStart: 0, sectors: 4, hardware: [[CGPoint(x: 1142, y: 586), CGPoint(x: 1182, y: 576), CGPoint(x: 1271, y: 762), CGPoint(x: 1274, y: 792), CGPoint(x: 1240, y: 813), CGPoint(x: 1219, y: 782)], [CGPoint(x: 1158, y: 713), CGPoint(x: 1200, y: 710), CGPoint(x: 1235, y: 771), CGPoint(x: 1218, y: 813), CGPoint(x: 1176, y: 813)]]),
        ],
        "axolotl": [
            .init(radius: 121, hub: 33, sectorStart: 90, sectors: 4, hardware: [[CGPoint(x: 310, y: 766), CGPoint(x: 664, y: 713), CGPoint(x: 677, y: 760), CGPoint(x: 355, y: 817), CGPoint(x: 308, y: 811)], [CGPoint(x: 348, y: 704), CGPoint(x: 391, y: 704), CGPoint(x: 414, y: 745), CGPoint(x: 373, y: 764), CGPoint(x: 344, y: 751)], [CGPoint(x: 365, y: 700), CGPoint(x: 604, y: 695), CGPoint(x: 606, y: 717), CGPoint(x: 362, y: 723)], [CGPoint(x: 355, y: 833), CGPoint(x: 612, y: 783), CGPoint(x: 617, y: 800), CGPoint(x: 354, y: 852)]]),
            .init(radius: 121, hub: 38, sectorStart: 0, sectors: 4, hardware: [[CGPoint(x: 1140, y: 622), CGPoint(x: 1180, y: 597), CGPoint(x: 1258, y: 766), CGPoint(x: 1277, y: 788), CGPoint(x: 1263, y: 817), CGPoint(x: 1221, y: 820), CGPoint(x: 1200, y: 779)], [CGPoint(x: 1160, y: 746), CGPoint(x: 1208, y: 738), CGPoint(x: 1227, y: 781), CGPoint(x: 1213, y: 817), CGPoint(x: 1169, y: 817)]]),
        ],
    ]
}
