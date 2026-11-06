// 自动生成：与网页版 data/gifts.js 完全一致
import Foundation

struct GiftItem: Codable, Hashable, Identifiable {
    let id: String
    let cat: String
    let price: Int
    let tags: [String]
    let title: String
    let desc: String

    var priceText: String {
        ["¥100 以内", "¥100–300", "¥300–800", "¥800 以上"][max(0, min(3, price - 1))]
    }
}

let builtInGifts: [GiftItem] = [
    GiftItem(id: "g01", cat: "走心", price: 1, tags: ["走心", "仪式感", "浪漫"], title: "手写一封「今年我记得的 12 件小事」", desc: "把她随口说过的、你当时没接话的那些，一条条写下来。这封信比任何东西都难被替代。"),
    GiftItem(id: "g02", cat: "走心", price: 2, tags: ["走心", "实用", "暖心"], title: "清空她购物车里放得最久的那一件", desc: "不用问她想要什么，答案早就在那儿躺了三个月。"),
    GiftItem(id: "g03", cat: "走心", price: 1, tags: ["走心", "暖心"], title: "她想看的那本书 + 你先读完写的三行感想", desc: "重点是那三行，不是书。"),
    GiftItem(id: "g04", cat: "走心", price: 2, tags: ["走心", "仪式感"], title: "定制台历：12 个月各放一张你手机里的她", desc: "挑照片的过程，会让你想起很多以为忘了的日子。"),
    GiftItem(id: "g05", cat: "走心", price: 1, tags: ["走心", "浪漫"], title: "录一段三分钟的视频，只说感谢", desc: "不要配乐，不要剪辑，看着镜头说完。"),
    GiftItem(id: "g06", cat: "走心", price: 2, tags: ["走心", "体验", "浪漫"], title: "把第一次约会那天的路线重走一遍", desc: "同一家店、同一段路，顺序都别改。"),
    GiftItem(id: "g07", cat: "走心", price: 1, tags: ["走心", "暖心", "陪伴"], title: "「这个月家务我全包」的券，并且真的兑现", desc: "礼物兑现不了，比没送更伤。"),
    GiftItem(id: "g08", cat: "走心", price: 2, tags: ["走心", "实用"], title: "换掉家里她抱怨过三次的那样东西", desc: "灯太暗、门太响、锅太重——她提过，就是想要。"),
    GiftItem(id: "g09", cat: "走心", price: 3, tags: ["走心", "体验"], title: "做一份「她说想去的地方」清单，顺手订好第一个", desc: "别停在清单，先把机票或车票买了。"),
    GiftItem(id: "g10", cat: "走心", price: 1, tags: ["走心", "暖心", "陪伴"], title: "连续一周，早餐做好再叫她", desc: "七天，一天都不许漏。"),
    GiftItem(id: "g11", cat: "走心", price: 3, tags: ["走心", "浪漫", "仪式感"], title: "内侧刻了一个日期的细项链", desc: "只有她知道那天是什么日子。"),
    GiftItem(id: "g12", cat: "走心", price: 1, tags: ["走心", "仪式感"], title: "写一封明年今日才准拆的信", desc: "让今年的心意，留到明年再被读到。"),
    GiftItem(id: "g13", cat: "实用", price: 3, tags: ["实用", "仪式感"], title: "她常用那支香水的补货装", desc: "快见底了你还记得，这件事本身就是礼物。"),
    GiftItem(id: "g14", cat: "实用", price: 3, tags: ["实用", "暖心"], title: "降噪耳机（如果她通勤超过半小时）", desc: "把那段路上的吵，替她挡掉一点。"),
    GiftItem(id: "g15", cat: "实用", price: 2, tags: ["实用", "暖心"], title: "肩颈按摩仪 / 热敷眼罩", desc: "她说过累，就别只回一句「早点睡」。"),
    GiftItem(id: "g16", cat: "实用", price: 2, tags: ["实用", "暖心"], title: "一套质感好一点的家居服", desc: "按她平时穿的颜色挑，别按你喜欢的挑。"),
    GiftItem(id: "g17", cat: "实用", price: 2, tags: ["实用"], title: "换掉那支用了两年的电动牙刷", desc: "不浪漫，但每天早晚都会被想起一次。"),
    GiftItem(id: "g18", cat: "实用", price: 3, tags: ["实用", "仪式感"], title: "一只她能装下电脑的通勤包", desc: "先翻翻她收藏夹，风格别自己发挥。"),
    GiftItem(id: "g19", cat: "实用", price: 3, tags: ["实用", "暖心", "陪伴"], title: "两个人的体检套餐，并且陪她去", desc: "把「注意身体」变成一件已经约好的事。"),
    GiftItem(id: "g20", cat: "实用", price: 2, tags: ["实用", "暖心"], title: "香薰机 + 她喜欢的那个味道", desc: "家里变好闻一点，回家的理由就多一点。"),
    GiftItem(id: "g21", cat: "实用", price: 1, tags: ["实用", "暖心"], title: "一只保温杯（她总说喝水少）", desc: "附一张纸条：今天记得喝。"),
    GiftItem(id: "g22", cat: "实用", price: 1, tags: ["实用"], title: "给她手机换块新电池 / 换个新壳", desc: "解决一个她懒得管的小麻烦。"),
    GiftItem(id: "g23", cat: "实用", price: 3, tags: ["实用", "暖心"], title: "一台不伤发的吹风机", desc: "每天省下十分钟，一年就是好几个小时。"),
    GiftItem(id: "g24", cat: "实用", price: 1, tags: ["实用", "走心"], title: "把她那双磨平的拖鞋换成新的", desc: "越小的事，越能证明你真的在看。"),
    GiftItem(id: "g25", cat: "体验", price: 2, tags: ["体验", "走心", "浪漫"], title: "订好她随口提过的那家店，连位子一起订", desc: "别说「改天去」，把时间发给她。"),
    GiftItem(id: "g26", cat: "体验", price: 3, tags: ["体验", "浪漫", "陪伴"], title: "周末两天、不带电脑的短途", desc: "只订住宿，行程留白，让她说了算。"),
    GiftItem(id: "g27", cat: "体验", price: 2, tags: ["体验", "仪式感"], title: "一起报个她提过的课：陶艺 / 烘焙 / 潜水", desc: "两个人都是新手，才好玩。"),
    GiftItem(id: "g28", cat: "体验", price: 3, tags: ["体验", "仪式感", "浪漫"], title: "一场她想看的演出，提前把票买好", desc: "别等开票那天你在开会。"),
    GiftItem(id: "g29", cat: "体验", price: 2, tags: ["体验", "浪漫"], title: "不带孩子的半天，只你们两个", desc: "先把带娃的人安排好，再告诉她。"),
    GiftItem(id: "g30", cat: "体验", price: 2, tags: ["体验", "仪式感", "走心"], title: "拍一组不摆拍的照片，洗出来装框", desc: "洗出来这件事，现在很少有人做了。"),
    GiftItem(id: "g31", cat: "体验", price: 3, tags: ["体验", "陪伴", "长辈"], title: "陪她回趟老家，不安排任何行程", desc: "就坐着，陪她待着。"),
    GiftItem(id: "g32", cat: "体验", price: 1, tags: ["体验", "陪伴", "暖心"], title: "一起把书桌或阳台收拾成她想要的样子", desc: "一下午，两个人，不看手机。"),
    GiftItem(id: "g33", cat: "体验", price: 1, tags: ["体验", "暖心", "陪伴"], title: "周末早上逛一次菜市场，你做饭", desc: "她只负责挑，你负责提和做。"),
    GiftItem(id: "g34", cat: "体验", price: 3, tags: ["体验", "暖心"], title: "订一次她没做过的 SPA / 头皮护理", desc: "把时间空出来，别让她自己找时间。"),
    GiftItem(id: "g35", cat: "体验", price: 1, tags: ["体验", "浪漫"], title: "看一次日出或日落，提前查好天气", desc: "免费，但要提前一天看云量。"),
    GiftItem(id: "g36", cat: "体验", price: 1, tags: ["体验", "走心", "浪漫"], title: "重看你们一起看的第一部电影", desc: "中途别处理工作消息。"),
    GiftItem(id: "g37", cat: "浪漫", price: 3, tags: ["浪漫", "仪式感"], title: "一束不贵、但连订 12 周的花", desc: "一次的心意容易，每周都记得才难。"),
    GiftItem(id: "g38", cat: "浪漫", price: 1, tags: ["浪漫", "陪伴", "走心"], title: "当天不加班，提前把日历空出来", desc: "最贵的礼物是时间，且不能补送。"),
    GiftItem(id: "g39", cat: "浪漫", price: 3, tags: ["浪漫", "仪式感"], title: "一枚刻了字的戒指或手链", desc: "字别太长，她懂就行。"),
    GiftItem(id: "g40", cat: "浪漫", price: 1, tags: ["浪漫", "走心"], title: "手机壁纸换成她挑的那张，一年不换", desc: "每次解锁都会被提醒一次。"),
    GiftItem(id: "g41", cat: "浪漫", price: 1, tags: ["浪漫", "走心", "暖心"], title: "在她包里塞一张只有一句话的纸条", desc: "她会在最累的时候翻到。"),
    GiftItem(id: "g42", cat: "浪漫", price: 3, tags: ["浪漫", "体验", "仪式感"], title: "订一间有浴缸的房，什么都不安排", desc: "没有行程，就是行程。"),
    GiftItem(id: "g43", cat: "浪漫", price: 1, tags: ["浪漫", "暖心"], title: "一个「不用解释就能早睡」的晚上", desc: "把家里所有事接过去，不问为什么。"),
    GiftItem(id: "g44", cat: "浪漫", price: 1, tags: ["浪漫", "走心"], title: "把她喜欢的歌做成清单，每首写一句为什么", desc: "歌单容易做，那几句为什么不容易。"),
    GiftItem(id: "g45", cat: "长辈", price: 2, tags: ["长辈", "走心", "暖心"], title: "给她妈妈也准备一份，署她的名", desc: "记得她惦记的人，比记得节日更重。"),
    GiftItem(id: "g46", cat: "长辈", price: 3, tags: ["长辈", "陪伴", "仪式感"], title: "两边老人一起吃顿饭，你来订、你买单", desc: "让她这天只负责坐着聊天。"),
    GiftItem(id: "g47", cat: "长辈", price: 3, tags: ["长辈", "实用", "陪伴"], title: "过年的年货和红包，提前备好", desc: "别让她一个人张罗到除夕下午。"),
    GiftItem(id: "g48", cat: "长辈", price: 2, tags: ["长辈", "暖心", "仪式感"], title: "月饼按她爸妈各自口味各买一份", desc: "甜咸分开，这种细节她会记很久。"),
]
