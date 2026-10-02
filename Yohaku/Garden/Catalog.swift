import Foundation
import UIKit

// Names, rarities, and rates come from catalog/CATALOG.md.
// Stand-in drawings are the flat pictures in CatalogArt.
// This file does not invent species.

enum CatalogKind: String, Codable {
    case plant
    case pot

    var title: String {
        switch self {
        case .plant: "植物"
        case .pot: "鉢"
        }
    }
}

enum Rarity: String, Codable, CaseIterable {
    case n, r, sr, ssr

    var label: String {
        switch self {
        case .n: "N"
        case .r: "R"
        case .sr: "SR"
        case .ssr: "SSR"
        }
    }

    var completionHours: Double {
        switch self {
        case .n: 30
        case .r: 50
        case .sr: 100
        case .ssr: 200
        }
    }

    var potMultiplier: Double {
        switch self {
        case .n: 1.1
        case .r: 1.2
        case .sr: 1.3
        case .ssr: 1.5
        }
    }

    /// Pool odds: N 75%, R 20%, SR 4.5%, SSR 0.5%.
    static func rolled(_ unit: Double) -> Rarity {
        if unit < 0.75 { return .n }
        if unit < 0.95 { return .r }
        if unit < 0.995 { return .sr }
        return .ssr
    }
}

enum GrowthMath {
    static let stageCount = 32

    static func requiredHours(plant: Rarity, pot: Rarity) -> Double {
        plant.completionHours / pot.potMultiplier
    }

    static func stageIndex(display: Double, bloomed: Bool) -> Int {
        if bloomed { return stageCount }
        let clamped = min(0.999, max(0, display))
        return min(stageCount - 1, Int(clamped * Double(stageCount)))
    }

    static func stageWord(_ index: Int) -> String {
        if index >= stageCount { return "咲" }
        switch index {
        case 0..<6: return "土"
        case 6..<13: return "芽"
        case 13..<21: return "葉"
        case 21..<28: return "蕾"
        default: return "花"
        }
    }

    static func hourText(_ value: Double) -> String {
        let whole = value.rounded()
        if abs(value - whole) < 0.001 {
            return String(Int(whole))
        }
        var text = String(format: "%.3f", value)
        while text.last == "0" {
            text.removeLast()
        }
        if text.last == "." {
            text.removeLast()
        }
        return text
    }
}

struct CatalogItem: Identifiable, Hashable {
    let name: String
    let rarity: Rarity
    let kind: CatalogKind
    let percentText: String
    let imageName: String?
    let imageExtension: String?
    let standIn: Bool
    let sourceNote: String

    var id: String { name }

    var bundledURL: URL? {
        guard let imageName, let imageExtension else { return nil }
        let ext = imageExtension.hasPrefix(".") ? String(imageExtension.dropFirst()) : imageExtension
        return Bundle.main.url(
            forResource: imageName,
            withExtension: ext,
            subdirectory: "CatalogArt"
        )
    }

    var bundledImage: UIImage? {
        guard let bundledURL else { return nil }
        return UIImage(contentsOfFile: bundledURL.path)
    }
}

enum Catalog {
    static let starterPlant = "蒲公英"
    static let starterPot = "丸"
    static let holdingCap = 80

    static func item(_ name: String, kind: CatalogKind) -> CatalogItem? {
        switch kind {
        case .plant: return plantIndex[name]
        case .pot: return potIndex[name]
        }
    }

    static func items(_ kind: CatalogKind) -> [CatalogItem] {
        kind == .plant ? plants : pots
    }

    static func roll(kind: CatalogKind, rarityUnit: Double, indexUnit: Double) -> CatalogItem {
        let rarity = Rarity.rolled(rarityUnit)
        let pool = items(kind).filter { $0.rarity == rarity }
        let index = min(pool.count - 1, Int(indexUnit * Double(pool.count)))
        return pool[max(0, index)]
    }

    static let plantIndex: [String: CatalogItem] = Dictionary(uniqueKeysWithValues: plants.map { ($0.name, $0) })
    static let potIndex: [String: CatalogItem] = Dictionary(uniqueKeysWithValues: pots.map { ($0.name, $0) })

    static let plants: [CatalogItem] = [
        CatalogItem(name: "蒲公英", rarity: .n, kind: .plant, percentText: "1.875%", imageName: "plant-n-tampopo", imageExtension: ".png", standIn: true, sourceNote: "art/plant-n-tampopo.png"),
        CatalogItem(name: "白詰草", rarity: .n, kind: .plant, percentText: "1.875%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "ffdb09cdf7a8d7d19438afb003e85c13730e7a97ca993aef05ccb7f768320389.jpg 上段左から2"),
        CatalogItem(name: "雑草", rarity: .n, kind: .plant, percentText: "1.875%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "ffdb09cdf7a8d7d19438afb003e85c13730e7a97ca993aef05ccb7f768320389.jpg 上段左から3"),
        CatalogItem(name: "蓬", rarity: .n, kind: .plant, percentText: "1.875%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "ffdb09cdf7a8d7d19438afb003e85c13730e7a97ca993aef05ccb7f768320389.jpg 上段左から4"),
        CatalogItem(name: "猫じゃらし", rarity: .n, kind: .plant, percentText: "1.875%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "ffdb09cdf7a8d7d19438afb003e85c13730e7a97ca993aef05ccb7f768320389.jpg 上段左から5"),
        CatalogItem(name: "オオバコ", rarity: .n, kind: .plant, percentText: "1.875%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "ffdb09cdf7a8d7d19438afb003e85c13730e7a97ca993aef05ccb7f768320389.jpg 下段左から1"),
        CatalogItem(name: "ドクダミ", rarity: .n, kind: .plant, percentText: "1.875%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "ffdb09cdf7a8d7d19438afb003e85c13730e7a97ca993aef05ccb7f768320389.jpg 下段左から2"),
        CatalogItem(name: "ハコベ", rarity: .n, kind: .plant, percentText: "1.875%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "ffdb09cdf7a8d7d19438afb003e85c13730e7a97ca993aef05ccb7f768320389.jpg 下段左から3"),
        CatalogItem(name: "ナズナ", rarity: .n, kind: .plant, percentText: "1.875%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "1948048f901039aac206e7413c28b7cb869f45fffc69c23c415d01976c8d9a29.jpg 左から1"),
        CatalogItem(name: "スギナ", rarity: .n, kind: .plant, percentText: "1.875%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "ffdb09cdf7a8d7d19438afb003e85c13730e7a97ca993aef05ccb7f768320389.jpg 下段左から5"),
        CatalogItem(name: "ツユクサ", rarity: .n, kind: .plant, percentText: "1.875%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "9fcdbf56986a98bcc43a8f16d635e3cdaff00a45eb62142edddaa2b68666af7e.jpg 上段左から1"),
        CatalogItem(name: "カタバミ", rarity: .n, kind: .plant, percentText: "1.875%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "9fcdbf56986a98bcc43a8f16d635e3cdaff00a45eb62142edddaa2b68666af7e.jpg 上段左から2"),
        CatalogItem(name: "オヒシバ", rarity: .n, kind: .plant, percentText: "1.875%", imageName: "plant-n-ohishiba", imageExtension: ".png", standIn: true, sourceNote: "art/plant-n-ohishiba.png"),
        CatalogItem(name: "メヒシバ", rarity: .n, kind: .plant, percentText: "1.875%", imageName: "plant-n-mehishiba", imageExtension: ".png", standIn: true, sourceNote: "art/plant-n-mehishiba.png"),
        CatalogItem(name: "ホトケノザ", rarity: .n, kind: .plant, percentText: "1.875%", imageName: "plant-n-hotokenoza", imageExtension: ".png", standIn: true, sourceNote: "art/plant-n-hotokenoza.png"),
        CatalogItem(name: "カラスノエンドウ", rarity: .n, kind: .plant, percentText: "1.875%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "9fcdbf56986a98bcc43a8f16d635e3cdaff00a45eb62142edddaa2b68666af7e.jpg 下段左から1"),
        CatalogItem(name: "ヒメジョオン", rarity: .n, kind: .plant, percentText: "1.875%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "9fcdbf56986a98bcc43a8f16d635e3cdaff00a45eb62142edddaa2b68666af7e.jpg 下段左から2"),
        CatalogItem(name: "ハルジオン", rarity: .n, kind: .plant, percentText: "1.875%", imageName: "plant-n-harujion", imageExtension: ".png", standIn: true, sourceNote: "art/plant-n-harujion.png"),
        CatalogItem(name: "ノゲシ", rarity: .n, kind: .plant, percentText: "1.875%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "9fcdbf56986a98bcc43a8f16d635e3cdaff00a45eb62142edddaa2b68666af7e.jpg 下段左から4"),
        CatalogItem(name: "ハハコグサ", rarity: .n, kind: .plant, percentText: "1.875%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "9fcdbf56986a98bcc43a8f16d635e3cdaff00a45eb62142edddaa2b68666af7e.jpg 下段左から5"),
        CatalogItem(name: "セイタカアワダチソウ", rarity: .n, kind: .plant, percentText: "1.875%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "e395d52c863e2972cb7316f9e9f69038edb6aa892af10bf413b2e073acfd96c3.jpg 上段左から1"),
        CatalogItem(name: "オオイヌノフグリ", rarity: .n, kind: .plant, percentText: "1.875%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "e395d52c863e2972cb7316f9e9f69038edb6aa892af10bf413b2e073acfd96c3.jpg 上段左から2"),
        CatalogItem(name: "ヨモギ", rarity: .n, kind: .plant, percentText: "1.875%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "e395d52c863e2972cb7316f9e9f69038edb6aa892af10bf413b2e073acfd96c3.jpg 上段左から3"),
        CatalogItem(name: "ススキ", rarity: .n, kind: .plant, percentText: "1.875%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "e395d52c863e2972cb7316f9e9f69038edb6aa892af10bf413b2e073acfd96c3.jpg 上段左から4"),
        CatalogItem(name: "カヤツリグサ", rarity: .n, kind: .plant, percentText: "1.875%", imageName: "plant-n-kayatsurigusa", imageExtension: ".png", standIn: true, sourceNote: "art/plant-n-kayatsurigusa.png"),
        CatalogItem(name: "イヌタデ", rarity: .n, kind: .plant, percentText: "1.875%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "e395d52c863e2972cb7316f9e9f69038edb6aa892af10bf413b2e073acfd96c3.jpg 下段左から1"),
        CatalogItem(name: "エノコログサ", rarity: .n, kind: .plant, percentText: "1.875%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "e395d52c863e2972cb7316f9e9f69038edb6aa892af10bf413b2e073acfd96c3.jpg 下段左から2"),
        CatalogItem(name: "アカザ", rarity: .n, kind: .plant, percentText: "1.875%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "e395d52c863e2972cb7316f9e9f69038edb6aa892af10bf413b2e073acfd96c3.jpg 下段左から3"),
        CatalogItem(name: "シバ", rarity: .n, kind: .plant, percentText: "1.875%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "e395d52c863e2972cb7316f9e9f69038edb6aa892af10bf413b2e073acfd96c3.jpg 下段左から4"),
        CatalogItem(name: "クズ", rarity: .n, kind: .plant, percentText: "1.875%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "e395d52c863e2972cb7316f9e9f69038edb6aa892af10bf413b2e073acfd96c3.jpg 下段左から5"),
        CatalogItem(name: "スズメノテッポウ", rarity: .n, kind: .plant, percentText: "1.875%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "f5127931819ed7ce6750a8baac966e52a0fb23c9fdba595adc557bba2953f34e.jpg 上段左から1"),
        CatalogItem(name: "イヌビエ", rarity: .n, kind: .plant, percentText: "1.875%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "f5127931819ed7ce6750a8baac966e52a0fb23c9fdba595adc557bba2953f34e.jpg 上段左から2"),
        CatalogItem(name: "イヌガラシ", rarity: .n, kind: .plant, percentText: "1.875%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "f5127931819ed7ce6750a8baac966e52a0fb23c9fdba595adc557bba2953f34e.jpg 上段左から3"),
        CatalogItem(name: "カラスムギ", rarity: .n, kind: .plant, percentText: "1.875%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "f5127931819ed7ce6750a8baac966e52a0fb23c9fdba595adc557bba2953f34e.jpg 上段左から4"),
        CatalogItem(name: "ヤブガラシ", rarity: .n, kind: .plant, percentText: "1.875%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "f5127931819ed7ce6750a8baac966e52a0fb23c9fdba595adc557bba2953f34e.jpg 上段左から5"),
        CatalogItem(name: "ジシバリ", rarity: .n, kind: .plant, percentText: "1.875%", imageName: "plant-n-jishibari", imageExtension: ".png", standIn: true, sourceNote: "art/plant-n-jishibari.png"),
        CatalogItem(name: "ウラジロ", rarity: .n, kind: .plant, percentText: "1.875%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "f5127931819ed7ce6750a8baac966e52a0fb23c9fdba595adc557bba2953f34e.jpg 下段左から2"),
        CatalogItem(name: "ヤブラン", rarity: .n, kind: .plant, percentText: "1.875%", imageName: "plant-n-yaburan", imageExtension: ".png", standIn: true, sourceNote: "art/plant-n-yaburan.png"),
        CatalogItem(name: "コケ", rarity: .n, kind: .plant, percentText: "1.875%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "f5127931819ed7ce6750a8baac966e52a0fb23c9fdba595adc557bba2953f34e.jpg 下段左から4"),
        CatalogItem(name: "スズメノカタビラ", rarity: .n, kind: .plant, percentText: "1.875%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "f5127931819ed7ce6750a8baac966e52a0fb23c9fdba595adc557bba2953f34e.jpg 下段左から5"),
        CatalogItem(name: "雛菊", rarity: .r, kind: .plant, percentText: "0.833%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "3593b945f93a4a808708093cd5d69a55bbfe6f40e1cf93226a858c5bfb33c3c9.jpg 上段左から1"),
        CatalogItem(name: "董", rarity: .r, kind: .plant, percentText: "0.833%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "3593b945f93a4a808708093cd5d69a55bbfe6f40e1cf93226a858c5bfb33c3c9.jpg 上段左から2"),
        CatalogItem(name: "羊歯", rarity: .r, kind: .plant, percentText: "0.833%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "3593b945f93a4a808708093cd5d69a55bbfe6f40e1cf93226a858c5bfb33c3c9.jpg 上段左から3"),
        CatalogItem(name: "石楠花", rarity: .r, kind: .plant, percentText: "0.833%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "3593b945f93a4a808708093cd5d69a55bbfe6f40e1cf93226a858c5bfb33c3c9.jpg 上段左から4"),
        CatalogItem(name: "朝顔", rarity: .r, kind: .plant, percentText: "0.833%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "3593b945f93a4a808708093cd5d69a55bbfe6f40e1cf93226a858c5bfb33c3c9.jpg 下段左から1"),
        CatalogItem(name: "パンジー", rarity: .r, kind: .plant, percentText: "0.833%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "3593b945f93a4a808708093cd5d69a55bbfe6f40e1cf93226a858c5bfb33c3c9.jpg 下段左から2"),
        CatalogItem(name: "マリーゴールド", rarity: .r, kind: .plant, percentText: "0.833%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "3593b945f93a4a808708093cd5d69a55bbfe6f40e1cf93226a858c5bfb33c3c9.jpg 下段左から3"),
        CatalogItem(name: "撫子", rarity: .r, kind: .plant, percentText: "0.833%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "3593b945f93a4a808708093cd5d69a55bbfe6f40e1cf93226a858c5bfb33c3c9.jpg 下段左から4"),
        CatalogItem(name: "日々草", rarity: .r, kind: .plant, percentText: "0.833%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "555cfe99897f234669cd3ba1c8ab89143b873e78af96a2be73e836e49114c35a.jpg 上段左から1"),
        CatalogItem(name: "ペチュニア", rarity: .r, kind: .plant, percentText: "0.833%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "555cfe99897f234669cd3ba1c8ab89143b873e78af96a2be73e836e49114c35a.jpg 上段左から2"),
        CatalogItem(name: "サルビア", rarity: .r, kind: .plant, percentText: "0.833%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "555cfe99897f234669cd3ba1c8ab89143b873e78af96a2be73e836e49114c35a.jpg 上段左から3"),
        CatalogItem(name: "シクラメン", rarity: .r, kind: .plant, percentText: "0.833%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "555cfe99897f234669cd3ba1c8ab89143b873e78af96a2be73e836e49114c35a.jpg 上段左から4"),
        CatalogItem(name: "ミモザ", rarity: .r, kind: .plant, percentText: "0.833%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "555cfe99897f234669cd3ba1c8ab89143b873e78af96a2be73e836e49114c35a.jpg 下段左から1"),
        CatalogItem(name: "ネモフィラ", rarity: .r, kind: .plant, percentText: "0.833%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "555cfe99897f234669cd3ba1c8ab89143b873e78af96a2be73e836e49114c35a.jpg 下段左から2"),
        CatalogItem(name: "シャガ", rarity: .r, kind: .plant, percentText: "0.833%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "555cfe99897f234669cd3ba1c8ab89143b873e78af96a2be73e836e49114c35a.jpg 下段左から3"),
        CatalogItem(name: "ベゴニア", rarity: .r, kind: .plant, percentText: "0.833%", imageName: "plant-r-begonia", imageExtension: ".png", standIn: true, sourceNote: "art/plant-r-begonia.png"),
        CatalogItem(name: "インパチエンス", rarity: .r, kind: .plant, percentText: "0.833%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "07f12cff2c11e80afea239862f91dc670a9fd19c042aed23a4a75c4d55ee0475.jpg 上段左から1"),
        CatalogItem(name: "ゼラニウム", rarity: .r, kind: .plant, percentText: "0.833%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "07f12cff2c11e80afea239862f91dc670a9fd19c042aed23a4a75c4d55ee0475.jpg 上段左から2"),
        CatalogItem(name: "マーガレット", rarity: .r, kind: .plant, percentText: "0.833%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "07f12cff2c11e80afea239862f91dc670a9fd19c042aed23a4a75c4d55ee0475.jpg 上段左から3"),
        CatalogItem(name: "ギボウシ", rarity: .r, kind: .plant, percentText: "0.833%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "07f12cff2c11e80afea239862f91dc670a9fd19c042aed23a4a75c4d55ee0475.jpg 上段左から4"),
        CatalogItem(name: "オシロイバナ", rarity: .r, kind: .plant, percentText: "0.833%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "07f12cff2c11e80afea239862f91dc670a9fd19c042aed23a4a75c4d55ee0475.jpg 下段左から1"),
        CatalogItem(name: "ホウセンカ", rarity: .r, kind: .plant, percentText: "0.833%", imageName: "plant-r-housenka", imageExtension: ".png", standIn: true, sourceNote: "art/plant-r-housenka.png"),
        CatalogItem(name: "キンセンカ", rarity: .r, kind: .plant, percentText: "0.833%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "07f12cff2c11e80afea239862f91dc670a9fd19c042aed23a4a75c4d55ee0475.jpg 下段左から3"),
        CatalogItem(name: "ストック", rarity: .r, kind: .plant, percentText: "0.833%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "07f12cff2c11e80afea239862f91dc670a9fd19c042aed23a4a75c4d55ee0475.jpg 下段左から4"),
        CatalogItem(name: "松", rarity: .sr, kind: .plant, percentText: "0.375%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "80806977783ff3f9da66e89c41da951e621c02c856223639cefe781ca6fdfd01.jpg 上段左から1"),
        CatalogItem(name: "白椿", rarity: .sr, kind: .plant, percentText: "0.375%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "80806977783ff3f9da66e89c41da951e621c02c856223639cefe781ca6fdfd01.jpg 上段左から2"),
        CatalogItem(name: "南天", rarity: .sr, kind: .plant, percentText: "0.375%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "1948048f901039aac206e7413c28b7cb869f45fffc69c23c415d01976c8d9a29.jpg 左から3"),
        CatalogItem(name: "紫陽花", rarity: .sr, kind: .plant, percentText: "0.375%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "80806977783ff3f9da66e89c41da951e621c02c856223639cefe781ca6fdfd01.jpg 上段左から4"),
        CatalogItem(name: "水仙", rarity: .sr, kind: .plant, percentText: "0.375%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "80806977783ff3f9da66e89c41da951e621c02c856223639cefe781ca6fdfd01.jpg 上段左から5"),
        CatalogItem(name: "彼岸花", rarity: .sr, kind: .plant, percentText: "0.375%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "80806977783ff3f9da66e89c41da951e621c02c856223639cefe781ca6fdfd01.jpg 上段左から6"),
        CatalogItem(name: "桔梗", rarity: .sr, kind: .plant, percentText: "0.375%", imageName: "plant-sr-kikyo", imageExtension: ".png", standIn: true, sourceNote: "art/plant-sr-kikyo.png"),
        CatalogItem(name: "沈丁花", rarity: .sr, kind: .plant, percentText: "0.375%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "80806977783ff3f9da66e89c41da951e621c02c856223639cefe781ca6fdfd01.jpg 下段左から2"),
        CatalogItem(name: "蝋梅", rarity: .sr, kind: .plant, percentText: "0.375%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "80806977783ff3f9da66e89c41da951e621c02c856223639cefe781ca6fdfd01.jpg 下段左から3"),
        CatalogItem(name: "紅葉", rarity: .sr, kind: .plant, percentText: "0.375%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "80806977783ff3f9da66e89c41da951e621c02c856223639cefe781ca6fdfd01.jpg 下段左から4"),
        CatalogItem(name: "山茶花", rarity: .sr, kind: .plant, percentText: "0.375%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "80806977783ff3f9da66e89c41da951e621c02c856223639cefe781ca6fdfd01.jpg 下段左から5"),
        CatalogItem(name: "リンドウ", rarity: .sr, kind: .plant, percentText: "0.375%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "80806977783ff3f9da66e89c41da951e621c02c856223639cefe781ca6fdfd01.jpg 下段左から6"),
        CatalogItem(name: "白菊", rarity: .ssr, kind: .plant, percentText: "0.125%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "5850142246f2acc999bb6401850b3ddbf2331b66ae133d191c8433f771e454d1.jpg 左から1"),
        CatalogItem(name: "百合", rarity: .ssr, kind: .plant, percentText: "0.125%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "5850142246f2acc999bb6401850b3ddbf2331b66ae133d191c8433f771e454d1.jpg 左から2"),
        CatalogItem(name: "藤", rarity: .ssr, kind: .plant, percentText: "0.125%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "5850142246f2acc999bb6401850b3ddbf2331b66ae133d191c8433f771e454d1.jpg 左から3"),
        CatalogItem(name: "ラフレシア", rarity: .ssr, kind: .plant, percentText: "0.125%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "5850142246f2acc999bb6401850b3ddbf2331b66ae133d191c8433f771e454d1.jpg 左から4（成長段階は 092d2376f6572a9ad57d5cf8bac59bd813a273e4b75b304fe295c55fb4312661.jpg。再描画していない）"),
    ]

    static let pots: [CatalogItem] = [
        CatalogItem(name: "丸", rarity: .n, kind: .pot, percentText: "1.875%", imageName: "b6c72_r0c0", imageExtension: ".jpg", standIn: false, sourceNote: "b6c72ae0a55c9512bacfca790eaa3037daec9e2c7468552871f4ba5fcde95e05.jpg 上段左から1"),
        CatalogItem(name: "細筒", rarity: .n, kind: .pot, percentText: "1.875%", imageName: "b6c72_r0c1", imageExtension: ".jpg", standIn: false, sourceNote: "b6c72ae0a55c9512bacfca790eaa3037daec9e2c7468552871f4ba5fcde95e05.jpg 上段左から2"),
        CatalogItem(name: "杯", rarity: .n, kind: .pot, percentText: "1.875%", imageName: "b6c72_r0c2", imageExtension: ".jpg", standIn: false, sourceNote: "b6c72ae0a55c9512bacfca790eaa3037daec9e2c7468552871f4ba5fcde95e05.jpg 上段左から3"),
        CatalogItem(name: "角", rarity: .n, kind: .pot, percentText: "1.875%", imageName: "pot-n-kaku", imageExtension: ".png", standIn: true, sourceNote: "art/pot-n-kaku.png"),
        CatalogItem(name: "浅鉢", rarity: .n, kind: .pot, percentText: "1.875%", imageName: "b6c72_r0c4", imageExtension: ".jpg", standIn: false, sourceNote: "b6c72ae0a55c9512bacfca790eaa3037daec9e2c7468552871f4ba5fcde95e05.jpg 上段左から5"),
        CatalogItem(name: "深鉢", rarity: .n, kind: .pot, percentText: "1.875%", imageName: "b6c72_r1c0", imageExtension: ".jpg", standIn: false, sourceNote: "b6c72ae0a55c9512bacfca790eaa3037daec9e2c7468552871f4ba5fcde95e05.jpg 下段左から1"),
        CatalogItem(name: "平鉢", rarity: .n, kind: .pot, percentText: "1.875%", imageName: "b6c72_r1c1", imageExtension: ".jpg", standIn: false, sourceNote: "b6c72ae0a55c9512bacfca790eaa3037daec9e2c7468552871f4ba5fcde95e05.jpg 下段左から2"),
        CatalogItem(name: "小鉢", rarity: .n, kind: .pot, percentText: "1.875%", imageName: "b6c72_r1c2", imageExtension: ".jpg", standIn: false, sourceNote: "b6c72ae0a55c9512bacfca790eaa3037daec9e2c7468552871f4ba5fcde95e05.jpg 下段左から3"),
        CatalogItem(name: "広口", rarity: .n, kind: .pot, percentText: "1.875%", imageName: "b6c72_r1c3", imageExtension: ".jpg", standIn: false, sourceNote: "b6c72ae0a55c9512bacfca790eaa3037daec9e2c7468552871f4ba5fcde95e05.jpg 下段左から4"),
        CatalogItem(name: "筒鉢", rarity: .n, kind: .pot, percentText: "1.875%", imageName: "b6c72_r1c4", imageExtension: ".jpg", standIn: false, sourceNote: "b6c72ae0a55c9512bacfca790eaa3037daec9e2c7468552871f4ba5fcde95e05.jpg 下段左から5"),
        CatalogItem(name: "丸浅", rarity: .n, kind: .pot, percentText: "1.875%", imageName: "pot-n-maruasa", imageExtension: ".png", standIn: true, sourceNote: "art/pot-n-maruasa.png"),
        CatalogItem(name: "丸深", rarity: .n, kind: .pot, percentText: "1.875%", imageName: "pot-n-marufuka", imageExtension: ".png", standIn: true, sourceNote: "art/pot-n-marufuka.png"),
        CatalogItem(name: "角浅", rarity: .n, kind: .pot, percentText: "1.875%", imageName: "pot-n-kakiasa", imageExtension: ".png", standIn: true, sourceNote: "art/pot-n-kakiasa.png"),
        CatalogItem(name: "角深", rarity: .n, kind: .pot, percentText: "1.875%", imageName: "pot-n-kakifuka", imageExtension: ".png", standIn: true, sourceNote: "art/pot-n-kakifuka.png"),
        CatalogItem(name: "白土", rarity: .n, kind: .pot, percentText: "1.875%", imageName: "c579_r0c4", imageExtension: ".jpg", standIn: false, sourceNote: "c5795d84f897f6c380dcc24c243efd8631b6271341390981089580940d6f3bde.jpg 上段左から5"),
        CatalogItem(name: "灰土", rarity: .n, kind: .pot, percentText: "1.875%", imageName: "c579_r1c0", imageExtension: ".jpg", standIn: false, sourceNote: "c5795d84f897f6c380dcc24c243efd8631b6271341390981089580940d6f3bde.jpg 下段左から1"),
        CatalogItem(name: "砂土", rarity: .n, kind: .pot, percentText: "1.875%", imageName: "pot-n-sunatsuchi", imageExtension: ".png", standIn: true, sourceNote: "art/pot-n-sunatsuchi.png"),
        CatalogItem(name: "素焼", rarity: .n, kind: .pot, percentText: "1.875%", imageName: "pot-n-suyaki", imageExtension: ".png", standIn: true, sourceNote: "art/pot-n-suyaki.png"),
        CatalogItem(name: "粗土", rarity: .n, kind: .pot, percentText: "1.875%", imageName: "pot-n-aratsuchi", imageExtension: ".png", standIn: true, sourceNote: "art/pot-n-aratsuchi.png"),
        CatalogItem(name: "淡土", rarity: .n, kind: .pot, percentText: "1.875%", imageName: "pot-n-awatsuchi", imageExtension: ".png", standIn: true, sourceNote: "art/pot-n-awatsuchi.png"),
        CatalogItem(name: "小丸", rarity: .n, kind: .pot, percentText: "1.875%", imageName: "d1e1_r0c0", imageExtension: ".jpg", standIn: false, sourceNote: "d1e1d9d43eabf70cff0e408202b6826b0017a85ba080af89412704ea9386859e.jpg 上段左から1"),
        CatalogItem(name: "大丸", rarity: .n, kind: .pot, percentText: "1.875%", imageName: "d1e1_r0c1", imageExtension: ".jpg", standIn: false, sourceNote: "d1e1d9d43eabf70cff0e408202b6826b0017a85ba080af89412704ea9386859e.jpg 上段左から2"),
        CatalogItem(name: "低丸", rarity: .n, kind: .pot, percentText: "1.875%", imageName: "d1e1_r0c2", imageExtension: ".jpg", standIn: false, sourceNote: "d1e1d9d43eabf70cff0e408202b6826b0017a85ba080af89412704ea9386859e.jpg 上段左から3"),
        CatalogItem(name: "高丸", rarity: .n, kind: .pot, percentText: "1.875%", imageName: "pot-n-takamaru", imageExtension: ".png", standIn: true, sourceNote: "art/pot-n-takamaru.png"),
        CatalogItem(name: "口小", rarity: .n, kind: .pot, percentText: "1.875%", imageName: "d1e1_r0c4", imageExtension: ".jpg", standIn: false, sourceNote: "d1e1d9d43eabf70cff0e408202b6826b0017a85ba080af89412704ea9386859e.jpg 上段左から5"),
        CatalogItem(name: "口大", rarity: .n, kind: .pot, percentText: "1.875%", imageName: "d1e1_r1c0", imageExtension: ".jpg", standIn: false, sourceNote: "d1e1d9d43eabf70cff0e408202b6826b0017a85ba080af89412704ea9386859e.jpg 下段左から1"),
        CatalogItem(name: "腹丸", rarity: .n, kind: .pot, percentText: "1.875%", imageName: "d1e1_r1c1", imageExtension: ".jpg", standIn: false, sourceNote: "d1e1d9d43eabf70cff0e408202b6826b0017a85ba080af89412704ea9386859e.jpg 下段左から2"),
        CatalogItem(name: "腹浅", rarity: .n, kind: .pot, percentText: "1.875%", imageName: "pot-n-harasa", imageExtension: ".png", standIn: true, sourceNote: "art/pot-n-harasa.png"),
        CatalogItem(name: "茶碗", rarity: .n, kind: .pot, percentText: "1.875%", imageName: "d1e1_r1c3", imageExtension: ".jpg", standIn: false, sourceNote: "d1e1d9d43eabf70cff0e408202b6826b0017a85ba080af89412704ea9386859e.jpg 下段左から4"),
        CatalogItem(name: "水皿", rarity: .n, kind: .pot, percentText: "1.875%", imageName: "d1e1_r1c4", imageExtension: ".jpg", standIn: false, sourceNote: "d1e1d9d43eabf70cff0e408202b6826b0017a85ba080af89412704ea9386859e.jpg 下段左から5"),
        CatalogItem(name: "六角", rarity: .n, kind: .pot, percentText: "1.875%", imageName: "59f2_r0c0", imageExtension: ".jpg", standIn: false, sourceNote: "59f2c1d38d9c6398256e454796f2520e17255465c0e8e48d2df0f37074d45db7.jpg 上段左から1"),
        CatalogItem(name: "八角", rarity: .n, kind: .pot, percentText: "1.875%", imageName: "pot-n-hakkaku", imageExtension: ".png", standIn: true, sourceNote: "art/pot-n-hakkaku.png"),
        CatalogItem(name: "短筒", rarity: .n, kind: .pot, percentText: "1.875%", imageName: "59f2_r0c2", imageExtension: ".jpg", standIn: false, sourceNote: "59f2c1d38d9c6398256e454796f2520e17255465c0e8e48d2df0f37074d45db7.jpg 上段左から3"),
        CatalogItem(name: "高筒", rarity: .n, kind: .pot, percentText: "1.875%", imageName: "59f2_r0c3", imageExtension: ".jpg", standIn: false, sourceNote: "59f2c1d38d9c6398256e454796f2520e17255465c0e8e48d2df0f37074d45db7.jpg 上段左から4"),
        CatalogItem(name: "広筒", rarity: .n, kind: .pot, percentText: "1.875%", imageName: "59f2_r0c4", imageExtension: ".jpg", standIn: false, sourceNote: "59f2c1d38d9c6398256e454796f2520e17255465c0e8e48d2df0f37074d45db7.jpg 上段左から5"),
        CatalogItem(name: "細丸", rarity: .n, kind: .pot, percentText: "1.875%", imageName: "59f2_r1c0", imageExtension: ".jpg", standIn: false, sourceNote: "59f2c1d38d9c6398256e454796f2520e17255465c0e8e48d2df0f37074d45db7.jpg 下段左から1"),
        CatalogItem(name: "平丸", rarity: .n, kind: .pot, percentText: "1.875%", imageName: "59f2_r1c1", imageExtension: ".jpg", standIn: false, sourceNote: "59f2c1d38d9c6398256e454796f2520e17255465c0e8e48d2df0f37074d45db7.jpg 下段左から2"),
        CatalogItem(name: "深丸", rarity: .n, kind: .pot, percentText: "1.875%", imageName: "59f2_r1c2", imageExtension: ".jpg", standIn: false, sourceNote: "59f2c1d38d9c6398256e454796f2520e17255465c0e8e48d2df0f37074d45db7.jpg 下段左から3"),
        CatalogItem(name: "浅丸", rarity: .n, kind: .pot, percentText: "1.875%", imageName: "59f2_r1c3", imageExtension: ".jpg", standIn: false, sourceNote: "59f2c1d38d9c6398256e454796f2520e17255465c0e8e48d2df0f37074d45db7.jpg 下段左から4"),
        CatalogItem(name: "並鉢", rarity: .n, kind: .pot, percentText: "1.875%", imageName: "59f2_r1c4", imageExtension: ".jpg", standIn: false, sourceNote: "59f2c1d38d9c6398256e454796f2520e17255465c0e8e48d2df0f37074d45db7.jpg 下段左から5"),
        CatalogItem(name: "黒土", rarity: .r, kind: .pot, percentText: "0.833%", imageName: "f983_r0c0", imageExtension: ".jpg", standIn: false, sourceNote: "f9836cc348748017d222a2bb721cbadaff324e514ec9a8d59aa245626806d563.jpg 上段左から1"),
        CatalogItem(name: "粉引", rarity: .r, kind: .pot, percentText: "0.833%", imageName: "f983_r0c1", imageExtension: ".jpg", standIn: false, sourceNote: "f9836cc348748017d222a2bb721cbadaff324e514ec9a8d59aa245626806d563.jpg 上段左から2"),
        CatalogItem(name: "灰釉", rarity: .r, kind: .pot, percentText: "0.833%", imageName: "f983_r0c2", imageExtension: ".jpg", standIn: false, sourceNote: "f9836cc348748017d222a2bb721cbadaff324e514ec9a8d59aa245626806d563.jpg 上段左から3"),
        CatalogItem(name: "白釉", rarity: .r, kind: .pot, percentText: "0.833%", imageName: "f983_r0c3", imageExtension: ".jpg", standIn: false, sourceNote: "f9836cc348748017d222a2bb721cbadaff324e514ec9a8d59aa245626806d563.jpg 上段左から4"),
        CatalogItem(name: "乳白", rarity: .r, kind: .pot, percentText: "0.833%", imageName: "f983_r1c0", imageExtension: ".jpg", standIn: false, sourceNote: "f9836cc348748017d222a2bb721cbadaff324e514ec9a8d59aa245626806d563.jpg 下段左から1"),
        CatalogItem(name: "鉄粉", rarity: .r, kind: .pot, percentText: "0.833%", imageName: "f983_r1c1", imageExtension: ".jpg", standIn: false, sourceNote: "f9836cc348748017d222a2bb721cbadaff324e514ec9a8d59aa245626806d563.jpg 下段左から2"),
        CatalogItem(name: "志野", rarity: .r, kind: .pot, percentText: "0.833%", imageName: "f983_r1c2", imageExtension: ".jpg", standIn: false, sourceNote: "f9836cc348748017d222a2bb721cbadaff324e514ec9a8d59aa245626806d563.jpg 下段左から3"),
        CatalogItem(name: "織部", rarity: .r, kind: .pot, percentText: "0.833%", imageName: "f983_r1c3", imageExtension: ".jpg", standIn: false, sourceNote: "f9836cc348748017d222a2bb721cbadaff324e514ec9a8d59aa245626806d563.jpg 下段左から4"),
        CatalogItem(name: "高台", rarity: .r, kind: .pot, percentText: "0.833%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "7e6febff7396bbcbf901c4f564070e910004d2645b8f1d9a7a9e9e522af847ec.jpg 上段左から1"),
        CatalogItem(name: "脚付", rarity: .r, kind: .pot, percentText: "0.833%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "7e6febff7396bbcbf901c4f564070e910004d2645b8f1d9a7a9e9e522af847ec.jpg 上段左から2"),
        CatalogItem(name: "耳付", rarity: .r, kind: .pot, percentText: "0.833%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "7e6febff7396bbcbf901c4f564070e910004d2645b8f1d9a7a9e9e522af847ec.jpg 上段左から3"),
        CatalogItem(name: "片口", rarity: .r, kind: .pot, percentText: "0.833%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "7e6febff7396bbcbf901c4f564070e910004d2645b8f1d9a7a9e9e522af847ec.jpg 上段左から4"),
        CatalogItem(name: "輪花", rarity: .r, kind: .pot, percentText: "0.833%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "7e6febff7396bbcbf901c4f564070e910004d2645b8f1d9a7a9e9e522af847ec.jpg 下段左から1"),
        CatalogItem(name: "面取", rarity: .r, kind: .pot, percentText: "0.833%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "7e6febff7396bbcbf901c4f564070e910004d2645b8f1d9a7a9e9e522af847ec.jpg 下段左から2"),
        CatalogItem(name: "布目", rarity: .r, kind: .pot, percentText: "0.833%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "7e6febff7396bbcbf901c4f564070e910004d2645b8f1d9a7a9e9e522af847ec.jpg 下段左から3"),
        CatalogItem(name: "刷毛", rarity: .r, kind: .pot, percentText: "0.833%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "7e6febff7396bbcbf901c4f564070e910004d2645b8f1d9a7a9e9e522af847ec.jpg 下段左から4"),
        CatalogItem(name: "青磁", rarity: .r, kind: .pot, percentText: "0.833%", imageName: "pot-r-seiji", imageExtension: ".png", standIn: true, sourceNote: "art/pot-r-seiji.png"),
        CatalogItem(name: "黄瀬戸", rarity: .r, kind: .pot, percentText: "0.833%", imageName: "pot-r-kiseto", imageExtension: ".png", standIn: true, sourceNote: "art/pot-r-kiseto.png"),
        CatalogItem(name: "信楽", rarity: .r, kind: .pot, percentText: "0.833%", imageName: "pot-r-shigaraki", imageExtension: ".png", standIn: true, sourceNote: "art/pot-r-shigaraki.png"),
        CatalogItem(name: "三島", rarity: .r, kind: .pot, percentText: "0.833%", imageName: "pot-r-mishima", imageExtension: ".png", standIn: true, sourceNote: "art/pot-r-mishima.png"),
        CatalogItem(name: "益子", rarity: .r, kind: .pot, percentText: "0.833%", imageName: "pot-r-mashiko", imageExtension: ".png", standIn: true, sourceNote: "art/pot-r-mashiko.png"),
        CatalogItem(name: "京焼", rarity: .r, kind: .pot, percentText: "0.833%", imageName: "pot-r-kyo", imageExtension: ".png", standIn: true, sourceNote: "art/pot-r-kyo.png"),
        CatalogItem(name: "徳利", rarity: .r, kind: .pot, percentText: "0.833%", imageName: "pot-r-tokkuri", imageExtension: ".png", standIn: true, sourceNote: "art/pot-r-tokkuri.png"),
        CatalogItem(name: "刷毛目", rarity: .r, kind: .pot, percentText: "0.833%", imageName: "pot-r-hakeme", imageExtension: ".png", standIn: true, sourceNote: "art/pot-r-hakeme.png"),
        CatalogItem(name: "石", rarity: .sr, kind: .pot, percentText: "0.375%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "5f02d5a7e5d857a419a4d25bc7125b90df58bf2af03918dd1c2fdcc0e106844d.jpg 上段左から1"),
        CatalogItem(name: "砂岩", rarity: .sr, kind: .pot, percentText: "0.375%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "5f02d5a7e5d857a419a4d25bc7125b90df58bf2af03918dd1c2fdcc0e106844d.jpg 上段左から2"),
        CatalogItem(name: "切立", rarity: .sr, kind: .pot, percentText: "0.375%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "5f02d5a7e5d857a419a4d25bc7125b90df58bf2af03918dd1c2fdcc0e106844d.jpg 上段左から3"),
        CatalogItem(name: "鉄鉢", rarity: .sr, kind: .pot, percentText: "0.375%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "5f02d5a7e5d857a419a4d25bc7125b90df58bf2af03918dd1c2fdcc0e106844d.jpg 上段左から4"),
        CatalogItem(name: "黒釉", rarity: .sr, kind: .pot, percentText: "0.375%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "5f02d5a7e5d857a419a4d25bc7125b90df58bf2af03918dd1c2fdcc0e106844d.jpg 上段左から5"),
        CatalogItem(name: "窯変", rarity: .sr, kind: .pot, percentText: "0.375%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "5f02d5a7e5d857a419a4d25bc7125b90df58bf2af03918dd1c2fdcc0e106844d.jpg 上段左から6"),
        CatalogItem(name: "砂鉢", rarity: .sr, kind: .pot, percentText: "0.375%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "5f02d5a7e5d857a419a4d25bc7125b90df58bf2af03918dd1c2fdcc0e106844d.jpg 下段左から1"),
        CatalogItem(name: "石鉢", rarity: .sr, kind: .pot, percentText: "0.375%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "5f02d5a7e5d857a419a4d25bc7125b90df58bf2af03918dd1c2fdcc0e106844d.jpg 下段左から2"),
        CatalogItem(name: "面取石", rarity: .sr, kind: .pot, percentText: "0.375%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "5f02d5a7e5d857a419a4d25bc7125b90df58bf2af03918dd1c2fdcc0e106844d.jpg 下段左から3"),
        CatalogItem(name: "鎬", rarity: .sr, kind: .pot, percentText: "0.375%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "5f02d5a7e5d857a419a4d25bc7125b90df58bf2af03918dd1c2fdcc0e106844d.jpg 下段左から4"),
        CatalogItem(name: "安山岩", rarity: .sr, kind: .pot, percentText: "0.375%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "5f02d5a7e5d857a419a4d25bc7125b90df58bf2af03918dd1c2fdcc0e106844d.jpg 下段左から5"),
        CatalogItem(name: "花器", rarity: .sr, kind: .pot, percentText: "0.375%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "5f02d5a7e5d857a419a4d25bc7125b90df58bf2af03918dd1c2fdcc0e106844d.jpg 下段左から6"),
        CatalogItem(name: "薄磁", rarity: .ssr, kind: .pot, percentText: "0.125%", imageName: nil, imageExtension: nil, standIn: false, sourceNote: "915b40d128511b3ea15fa2486bec3687918293a0ec0c9ea53a94c6e74118fdf8.jpg（側面。承認済み。再描画していない）"),
        CatalogItem(name: "白磁", rarity: .ssr, kind: .pot, percentText: "0.125%", imageName: "pot-ssr-hakuji", imageExtension: ".png", standIn: true, sourceNote: "art/pot-ssr-hakuji.png"),
        CatalogItem(name: "淡磁", rarity: .ssr, kind: .pot, percentText: "0.125%", imageName: "pot-ssr-tanji", imageExtension: ".png", standIn: true, sourceNote: "art/pot-ssr-tanji.png"),
        CatalogItem(name: "灰磁", rarity: .ssr, kind: .pot, percentText: "0.125%", imageName: "pot-ssr-haiji", imageExtension: ".png", standIn: true, sourceNote: "art/pot-ssr-haiji.png"),
    ]
}

enum DropPack: String, CaseIterable, Identifiable {
    case forty = "yohaku_shizuku_40"
    case oneFifty = "yohaku_shizuku_150"
    case threeEighty = "yohaku_shizuku_380"
    case twelveHundred = "yohaku_shizuku_1200"
    case twentyTwoHundred = "yohaku_shizuku_2200"
    case fiveThousand = "yohaku_shizuku_5000"

    var id: String { rawValue }

    var drops: Int {
        switch self {
        case .forty: 40
        case .oneFifty: 150
        case .threeEighty: 380
        case .twelveHundred: 1200
        case .twentyTwoHundred: 2200
        case .fiveThousand: 5000
        }
    }

    static func matching(_ productID: String) -> DropPack? {
        DropPack(rawValue: productID)
    }
}
