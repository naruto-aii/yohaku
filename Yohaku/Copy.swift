import Foundation

enum Copy {
    static let appName = "余白"

    static let focus = "集中"
    static let rest = "休憩"
    static let streak = "連続"
    static let settings = "設定"
    static let close = "閉じる"
    static let back = "戻る"

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
    static let tenPull = "10回引く"
    static let oddsTitle = "出るもの"
    static let packs = "しずく"
    static let drops = "しずく"
    static let potWord = "鉢"
    static let plantWord = "植物"
    static let begin = "始める"
    static let continueGrow = "続ける"
    static let place = "棚に置く"
    static let nickname = "名前"
    static let nicknameHint = "空でも置けます。"
    static let shelfEmpty = "咲いた組み合わせは、ここに並びます。"
    static let tutorialLead = "はじめに、植物を一つ、鉢を一つ受け取ります。"
    static let tutorialPlant = "植物を引く"
    static let tutorialPot = "鉢を引く"
    static let tutorialDone = "蒲公英と丸から始まります。"
    static let chooseNoise = "音"
    static let choosePlant = "育てる植物"
    static let choosePot = "使う鉢"
    static let nothingFree = "空いているものがありません。"
    static let standIn = "差し替えの仮の平面イラスト"
    static let noPicture = "絵のファイルはボード上の位置だけが残っています。"
    static let packLead = "価格は App Store で表示されます。"
    static let oddsLead = "枠の中の一つずつです。"

    static func received(_ name: String) -> String {
        "\(name)を受け取りました。"
    }

    static func overflow(name: String, hours: String) -> String {
        "所持が80の\(name)です。数は増やさず、育ちの時間に \(hours) 時間足しました。"
    }

    static func holding(_ count: Int) -> String {
        "所持 \(count)"
    }

    static func stageCount(_ index: Int) -> String {
        let shown = min(GrowthMath.stageCount, index)
        return "\(shown)/\(GrowthMath.stageCount)"
    }
}
