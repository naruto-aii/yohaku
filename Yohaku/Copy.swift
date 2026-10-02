import Foundation

enum Copy {
    static let appName = "余白"

    static let focus = "集中"
    static let rest = "休憩"
    static let streak = "連続"
    static let settings = "設定"
    static let close = "閉じる"

    static let start = "開始"
    static let pause = "一時停止"
    static let minutes = "分"

    static let white = "白"
    static let pink = "ピンク"
    static let brown = "ブラウン"
    static let rain = "雨"
    static let locked = "ロック中"
    static let playing = "再生中"
    static let stopped = "停止"

    static let lengthsFixed = "長さを変えるには、余白をひらく"
    static let unlock = "余白をひらく"
    static let unlocked = "生涯アンロック済み"
    static let once = "生涯に一度だけの購入です。"
    static let sound = "音"
    static let soundValue = "ピンク、ブラウン、雨"
    static let time = "時間"
    static let timeValue = "集中と休憩の長さ"
    static let streakValue = "この iPhone に残します"
    static let openNow = "ひらいています"
    static let openDetail = "音、時間の長さ、連続の保存が使えます。"

    static let purchase = "購入する"
    static let purchasing = "処理しています"
    static let restore = "購入を復元する"
    static let loadingPrice = "価格を確認しています"
    static let priceUnavailable = "価格は App Store で表示されます"
    static let productMissing = "この環境では製品を読み込めません。製品 ID は yohaku_lifetime です。"
    static let purchaseFailed = "購入を完了できませんでした。"
    static let purchasePending = "購入の承認を待っています。"
    static let restored = "復元しました。"
    static let nothingToRestore = "復元できる購入はありません。"

    static let audioFailed = "音を開始できませんでした。"

    static let shelf = "棚"
    static let pull = "引く"
    static let potWord = "鉢"
    static let plantWord = "植物"
    static let grow = "育てる"
    static let pullThing = "引くもの"
    static let odds = "N 75%、R 20%、SR 4.5%、SSR 0.5%。同じ稀少度のなかでは、どれも同じ割合です。"
    static let materialHint = "集中が 60 分たまると、一つ増えます。"
    static let shelfEmpty = "咲いた花は、ここに並びます。"
    static let notGrowing = "まだ育っていません。"
    static let seedTitle = "育てるものを足す"
    static let seedDetail = "引くものを三つと、12 時間。育っている花があれば、その時間に足します。"
    static let addSeed = "足す"
    static let seedAdded = "足しました。"
    static let seedMissing = "この環境では製品を読み込めません。製品 ID は yohaku_seed です。"

    static func received(_ name: String) -> String {
        "\(name)を受け取りました。"
    }

    static func duplicateHours(kind: String, hours: String, bloomed: Bool) -> String {
        var text = "持っている\(kind)です。育っている植物に \(hours) 時間たしました。"
        if bloomed {
            text += "花が咲き、棚に置きました。"
        }
        return text
    }

    static func duplicateMaterial(kind: String) -> String {
        "持っている\(kind)です。引くものが 0.5 増えました。二つで一回引けます。"
    }

    static func pendingHours(_ hours: String) -> String {
        "次に育て始めると、\(hours) 時間から始まります。"
    }
}
