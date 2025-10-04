import SwiftUI

enum InfoLanguage: String, CaseIterable {
    case english = "English"
    case japanese = "日本語"
    case french = "Français"
    case german = "Deutsch"
    case chineseSimplified = "简体中文"
    case chineseTraditional = "繁體中文"
    case korean = "한국어"
    case spanish = "Español"
    case italian = "Italiano"
    case polish = "Polski"
    case russian = "Русский"
    case hindi = "हिन्दी"
    case arabic = "العربية"
    
    var flag: String {
        switch self {
        case .english: return "🇬🇧"
        case .japanese: return "🇯🇵"
        case .french: return "🇫🇷"
        case .german: return "🇩🇪"
        case .chineseSimplified: return "🇨🇳"
        case .chineseTraditional: return "🇹🇼"
        case .korean: return "🇰🇷"
        case .spanish: return "🇪🇸"
        case .italian: return "🇮🇹"
        case .polish: return "🇵🇱"
        case .russian: return "🇷🇺"
        case .hindi: return "🇮🇳"
        case .arabic: return "🇸🇦"
        }
    }
}

struct FAQItem: Identifiable {
    let id = UUID()
    let question: [InfoLanguage: String]
    let answer: [InfoLanguage: String]
}

struct InfoView: View {
    @AppStorage("showEnglish") var showEnglish = false
    @State private var selectedLanguage: InfoLanguage = .english
    @State private var expandedItems: Set<UUID> = []
    
    private let faqItems = [
        FAQItem(
            question: [
                .english: "When is Golden Gai open and when will it be closed?",
                .japanese: "ゴールデン街の営業時間は？",
                .french: "Quand est-ce que Golden Gai est ouvert et quand ferme-t-il ?",
                .german: "Wann ist Golden Gai geöffnet und wann geschlossen?",
                .chineseSimplified: "黄金街什么时候开门和关门？",
                .chineseTraditional: "黃金街什麼時候開門和關門？",
                .korean: "골든 가이는 언제 열고 언제 닫나요?",
                .spanish: "¿Cuándo está abierto y cerrado Golden Gai?",
                .italian: "Quando è aperto e chiuso Golden Gai?",
                .polish: "Kiedy Golden Gai jest otwarty i kiedy zamknięty?",
                .russian: "Когда Golden Gai открыт и когда закрыт?",
                .hindi: "गोल्डन गाई कब खुलता है और कब बंद होता है?",
                .arabic: "متى يفتح ومتى يغلق غولدن غاي?"
            ],
            answer: [
                .english: "The Golden Gai district never sleeps, but opening and closing hour schedule depends on each bar. Some bars make rotations to run for 24 hours, but it is still exceptional.",
                .japanese: "ゴールデン街は眠りませんが、営業時間は各バーによって異なります。バーテンダーが交代制で休み無しに営業しているバーもあります。",
                .french: "Le quartier de Golden Gai ne dort jamais, mais les horaires d'ouverture et de fermeture dépendent de chaque bar. Certains bars fonctionnent par rotation pour être ouverts 24h/24, mais c'est encore exceptionnel.",
                .german: "Das Golden Gai Viertel schläft nie, aber die Öffnungs- und Schließzeiten hängen von jeder Bar ab. Einige Bars arbeiten in Schichten, um 24 Stunden geöffnet zu sein, aber das ist immer noch eine Ausnahme.",
                .chineseSimplified: "黄金街地区永不眠息，但每个酒吧的营业时间各不相同。有些酒吧轮流营业以实现24小时开放，但这仍然是例外情况。",
                .chineseTraditional: "黃金街地區永不眠息，但每個酒吧的營業時間各不相同。有些酒吧輪流營業以實現24小時開放，但這仍然是例外情況。",
                .korean: "골든 가이 지구는 잠들지 않지만, 영업 시간은 각 바마다 다릅니다. 일부 바는 24시간 운영을 위해 교대로 운영하지만, 여전히 예외적입니다.",
                .spanish: "El distrito de Golden Gai nunca duerme, pero el horario de apertura y cierre depende de cada bar. Algunos bares hacen rotaciones para funcionar 24 horas, pero sigue siendo excepcional.",
                .italian: "Il quartiere di Golden Gai non dorme mai, ma gli orari di apertura e chiusura dipendono da ogni bar. Alcuni bar fanno turni per essere aperti 24 ore, ma è ancora eccezionale.",
                .polish: "Dzielnica Golden Gai nigdy nie śpi, ale godziny otwarcia i zamknięcia zależą od każdego baru. Niektóre bary pracują na zmiany, aby być otwarte 24 godziny, ale to wciąż wyjątek.",
                .russian: "Район Golden Gai никогда не спит, но часы работы зависят от каждого бара. Некоторые бары работают посменно, чтобы быть открытыми 24 часа, но это все еще исключение.",
                .hindi: "गोल्डन गाई जिला कभी नहीं सोता, लेकिन खुलने और बंद होने का समय प्रत्येक बार पर निर्भर करता है। कुछ बार 24 घंटे चलाने के लिए बदलाव करते हैं, लेकिन यह अभी भी असाधारण है।",
                .arabic: "منطقة غولدن غاي لا تنام أبدًا، لكن ساعات الفتح والإغلاق تعتمد على كل حانة. بعض الحانات تعمل بنظام المناوبات لتعمل 24 ساعة، لكن هذا لا يزال استثنائيًا."
            ]
        ),
        FAQItem(
            question: [
                .english: "What is cover charge?",
                .japanese: "カバーチャージとは何ですか？",
                .french: "Qu'est-ce que les frais de couverture ?",
                .german: "Was ist die Sitzplatzgebühr?",
                .chineseSimplified: "什么是座位费？",
                .chineseTraditional: "什麼是座位費？",
                .korean: "커버 차지란 무엇인가요?",
                .spanish: "¿Qué es el cargo por cubierto?",
                .italian: "Cos'è il coperto?",
                .polish: "Co to jest opłata wstępna?",
                .russian: "Что такое входная плата?",
                .hindi: "कवर चार्ज क्या है?",
                .arabic: "ما هي رسوم الغطاء؟"
            ],
            answer: [
                .english: "It is the initial payment you pay for the bar and it is kind of like entrance fee to the bar. The charge depends on the bar you visit, some are free of charge, better ask before you go inside.",
                .japanese: "スナックのお通し代のようなものです。料金は訪れるお店によって異なります。無い店もあります。入店前に確認することをお勧めします。",
                .french: "C'est le paiement initial que vous payez pour le bar et c'est un peu comme un droit d'entrée. Les frais dépendent du bar que vous visitez, certains sont gratuits, il vaut mieux demander avant d'entrer.",
                .german: "Es ist die anfängliche Zahlung, die Sie für die Bar zahlen, und es ist wie eine Eintrittsgebühr. Die Gebühr hängt von der Bar ab, die Sie besuchen, einige sind kostenlos, fragen Sie besser vorher.",
                .chineseSimplified: "这是您为酒吧支付的初始费用，类似于酒吧的入场费。费用取决于您访问的酒吧，有些是免费的，最好在进去之前询问。",
                .chineseTraditional: "這是您為酒吧支付的初始費用，類似於酒吧的入場費。費用取決於您訪問的酒吧，有些是免費的，最好在進去之前詢問。",
                .korean: "바에 지불하는 초기 비용으로 바의 입장료와 같은 것입니다. 요금은 방문하는 바에 따라 다르며, 일부는 무료입니다. 들어가기 전에 확인하는 것이 좋습니다.",
                .spanish: "Es el pago inicial que pagas por el bar y es como una tarifa de entrada. El cargo depende del bar que visites, algunos son gratis, mejor pregunta antes de entrar.",
                .italian: "È il pagamento iniziale che paghi per il bar ed è come una quota d'ingresso. Il costo dipende dal bar che visiti, alcuni sono gratuiti, meglio chiedere prima di entrare.",
                .polish: "To początkowa opłata, którą płacisz za bar i jest to coś w rodzaju opłaty wstępnej. Opłata zależy od baru, który odwiedzasz, niektóre są bezpłatne, lepiej zapytać przed wejściem.",
                .russian: "Это начальный платеж, который вы платите за бар, и это как плата за вход. Плата зависит от бара, который вы посещаете, некоторые бесплатны, лучше спросить перед входом.",
                .hindi: "यह बार के लिए आपके द्वारा भुगतान किया जाने वाला प्रारंभिक भुगतान है और यह बार के प्रवेश शुल्क की तरह है। शुल्क आपके द्वारा देखे गए बार पर निर्भर करता है, कुछ मुफ्त हैं, अंदर जाने से पहले पूछना बेहतर है।",
                .arabic: "هي الدفعة الأولية التي تدفعها للحانة وهي مثل رسوم الدخول. الرسوم تعتمد على الحانة التي تزورها، بعضها مجاني، من الأفضل السؤال قبل الدخول."
            ]
        ),
        FAQItem(
            question: [
                .english: "Do you have non-alcohol menu?",
                .japanese: "ノンアルコールメニューはありますか？",
                .french: "Avez-vous un menu sans alcool ?",
                .german: "Haben Sie ein alkoholfreies Menü?",
                .chineseSimplified: "有无酒精饮料菜单吗？",
                .chineseTraditional: "有無酒精飲料菜單嗎？",
                .korean: "무알코올 메뉴가 있나요?",
                .spanish: "¿Tienen menú sin alcohol?",
                .italian: "Avete un menu senza alcol?",
                .polish: "Czy macie menu bezalkoholowe?",
                .russian: "У вас есть безалкогольное меню?",
                .hindi: "क्या आपके पास नॉन-अल्कोहल मेनू है?",
                .arabic: "هل لديكم قائمة بدون كحول؟"
            ],
            answer: [
                .english: "Depends on the place you visit, most likely they do, but you need to ask one drink at least, even when you come with a group, once inside the bar.",
                .japanese: "店によって異なりますが、ほとんどの店にあります。ただし、グループで来店した場合でも、お店に入ったら一人一杯は注文するようにしましょう。",
                .french: "Cela dépend de l'endroit que vous visitez, ils en ont probablement, mais vous devez commander au moins une boisson, même si vous venez en groupe, une fois à l'intérieur du bar.",
                .german: "Das hängt vom Ort ab, den Sie besuchen. Wahrscheinlich haben sie welche, aber Sie müssen mindestens ein Getränk bestellen, auch wenn Sie mit einer Gruppe kommen, sobald Sie in der Bar sind.",
                .chineseSimplified: "取决于您访问的地方，很可能有，但即使您是团体前来，进入酒吧后也需要至少点一杯饮料。",
                .chineseTraditional: "取決於您訪問的地方，很可能有，但即使您是團體前來，進入酒吧後也需要至少點一杯飲料。",
                .korean: "방문하는 장소에 따라 다르지만, 대부분 있습니다. 하지만 그룹으로 오시더라도 바에 들어가면 최소한 한 잔은 주문해야 합니다.",
                .spanish: "Depende del lugar que visites, probablemente sí, pero necesitas pedir al menos una bebida, incluso cuando vienes en grupo, una vez dentro del bar.",
                .italian: "Dipende dal posto che visiti, probabilmente sì, ma devi ordinare almeno una bevanda, anche quando vieni in gruppo, una volta dentro al bar.",
                .polish: "Zależy od miejsca, które odwiedzasz, prawdopodobnie tak, ale musisz zamówić przynajmniej jeden drink, nawet gdy przychodzisz w grupie, gdy już jesteś w barze.",
                .russian: "Зависит от места, которое вы посещаете, скорее всего есть, но вам нужно заказать хотя бы один напиток, даже если вы пришли группой, как только окажетесь в баре.",
                .hindi: "यह उस जगह पर निर्भर करता है जहाँ आप जाते हैं, सबसे अधिक संभावना है कि हो, लेकिन आपको कम से कम एक पेय ऑर्डर करना होगा, भले ही आप एक समूह के साथ आएं, एक बार बार के अंदर।",
                .arabic: "يعتمد على المكان الذي تزوره، على الأرجح نعم، لكن يجب أن تطلب مشروبًا واحدًا على الأقل، حتى عندما تأتي مع مجموعة، بمجرد دخول الحانة."
            ]
        ),
        FAQItem(
            question: [
                .english: "What is member-only bar?",
                .japanese: "会員制バーとは？",
                .french: "Qu'est-ce qu'un bar réservé aux membres ?",
                .german: "Was ist eine Bar nur für Mitglieder?",
                .chineseSimplified: "什么是会员专用酒吧？",
                .chineseTraditional: "什麼是會員專用酒吧？",
                .korean: "회원 전용 바란 무엇인가요?",
                .spanish: "¿Qué es un bar solo para miembros?",
                .italian: "Cos'è un bar riservato ai soci?",
                .polish: "Co to jest bar tylko dla członków?",
                .russian: "Что такое бар только для членов?",
                .hindi: "केवल सदस्यों के लिए बार क्या है?",
                .arabic: "ما هي الحانة المخصصة للأعضاء فقط؟"
            ],
            answer: [
                .english: "Some bar only let in guests whom they know or with reference.",
                .japanese: "一部のお店は常連さんや紹介された方のみしか入店できない場合があります。",
                .french: "Certains bars n'acceptent que les clients qu'ils connaissent ou avec une référence.",
                .german: "Einige Bars lassen nur Gäste ein, die sie kennen oder die empfohlen wurden.",
                .chineseSimplified: "有些酒吧只允许他们认识的客人或有推荐的客人进入。",
                .chineseTraditional: "有些酒吧只允許他們認識的客人或有推薦的客人進入。",
                .korean: "일부 바는 그들이 아는 손님이나 소개를 받은 손님만 받습니다.",
                .spanish: "Algunos bares solo dejan entrar a invitados que conocen o con referencia.",
                .italian: "Alcuni bar fanno entrare solo ospiti che conoscono o con referenza.",
                .polish: "Niektóre bary wpuszczają tylko gości, których znają lub z poleceniem.",
                .russian: "Некоторые бары пускают только гостей, которых они знают или по рекомендации.",
                .hindi: "कुछ बार केवल उन मेहमानों को अनुमति देते हैं जिन्हें वे जानते हैं या संदर्भ के साथ।",
                .arabic: "بعض الحانات تسمح فقط للضيوف الذين يعرفونهم أو بالإحالة."
            ]
        ),
        FAQItem(
            question: [
                .english: "Can we pay with credit card?",
                .japanese: "クレジットカードで支払えますか？",
                .french: "Peut-on payer par carte de crédit ?",
                .german: "Können wir mit Kreditkarte bezahlen?",
                .chineseSimplified: "可以用信用卡支付吗？",
                .chineseTraditional: "可以用信用卡支付嗎？",
                .korean: "신용카드로 결제할 수 있나요?",
                .spanish: "¿Podemos pagar con tarjeta de crédito?",
                .italian: "Possiamo pagare con carta di credito?",
                .polish: "Czy możemy płacić kartą kredytową?",
                .russian: "Можем ли мы платить кредитной картой?",
                .hindi: "क्या हम क्रेडिट कार्ड से भुगतान कर सकते हैं?",
                .arabic: "هل يمكننا الدفع ببطاقة الائتمان؟"
            ],
            answer: [
                .english: "It depends on the bar you visit, some accept sometimes with some condition like when you pay above certain amount of money, and some only accept only cash, better to have cash ready.",
                .japanese: "訪れるお店によって異なります。一定金額以上の場合のみカードを受け付けるお店もあれば、現金払いのみのお店もあります。手元にキャッシュがない場合は事前に確認しましょう。",
                .french: "Cela dépend du bar que vous visitez, certains acceptent parfois avec certaines conditions comme lorsque vous payez au-dessus d'un certain montant, et certains n'acceptent que l'espèces, mieux vaut avoir de l'argent liquide.",
                .german: "Das hängt von der Bar ab, die Sie besuchen. Einige akzeptieren manchmal unter bestimmten Bedingungen, z. B. wenn Sie einen bestimmten Betrag überschreiten, und einige akzeptieren nur Bargeld. Es ist besser, Bargeld bereitzuhalten.",
                .chineseSimplified: "取决于您访问的酒吧，有些在某些条件下接受，比如当您支付超过一定金额时，有些只接受现金，最好准备好现金。",
                .chineseTraditional: "取決於您訪問的酒吧，有些在某些條件下接受，比如當您支付超過一定金額時，有些只接受現金，最好準備好現金。",
                .korean: "방문하는 바에 따라 다릅니다. 일부는 일정 금액 이상 결제 시와 같은 조건으로 때때로 받아들이며, 일부는 현금만 받습니다. 현금을 준비하는 것이 좋습니다.",
                .spanish: "Depende del bar que visites, algunos aceptan a veces con alguna condición como cuando pagas por encima de cierta cantidad de dinero, y algunos solo aceptan efectivo, mejor tener efectivo listo.",
                .italian: "Dipende dal bar che visiti, alcuni accettano a volte con qualche condizione come quando paghi sopra una certa somma di denaro, e alcuni accettano solo contanti, meglio avere contanti pronti.",
                .polish: "Zależy od baru, który odwiedzasz, niektóre akceptują czasami z jakimś warunkiem, jak gdy płacisz powyżej określonej kwoty, a niektóre akceptują tylko gotówkę, lepiej mieć gotówkę pod ręką.",
                .russian: "Зависит от бара, который вы посещаете, некоторые принимают иногда с некоторыми условиями, например, когда вы платите сумму выше определенной, а некоторые принимают только наличные, лучше иметь наличные.",
                .hindi: "यह उस बार पर निर्भर करता है जहाँ आप जाते हैं, कुछ कभी-कभी कुछ शर्तों के साथ स्वीकार करते हैं जैसे कि जब आप एक निश्चित राशि से ऊपर भुगतान करते हैं, और कुछ केवल नकद स्वीकार करते हैं, नकद तैयार रखना बेहतर है।",
                .arabic: "يعتمد على الحانة التي تزورها، بعضها يقبل أحيانًا بشرط معين مثل عندما تدفع فوق مبلغ معين، وبعضها يقبل النقد فقط، من الأفضل أن يكون لديك نقود جاهزة."
            ]
        )
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Fixed background image
                Image("InfoBackground")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header with language switcher
                    HStack {
                        Text(showEnglish ? "Guide Info" : "Guide Info")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Language picker
                        Menu {
                            ForEach(InfoLanguage.allCases, id: \.self) { language in
                                Button(action: {
                                    selectedLanguage = language
                                }) {
                                    HStack {
                                        Text(language.flag)
                                        Text(language.rawValue)
                                        if selectedLanguage == language {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Text(selectedLanguage.flag)
                                    .font(.title3)
                                Image(systemName: "globe")
                                    .foregroundColor(.white)
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.3))
                    
                    // FAQ List
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(faqItems) { item in
                                FAQRowView(
                                    item: item,
                                    language: selectedLanguage,
                                    isExpanded: expandedItems.contains(item.id),
                                    maxWidth: geometry.size.width - 32,
                                    onTap: {
                                        withAnimation(.spring(response: 0.3)) {
                                            if expandedItems.contains(item.id) {
                                                expandedItems.remove(item.id)
                                            } else {
                                                expandedItems.insert(item.id)
                                            }
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .onAppear {
                selectedLanguage = showEnglish ? .english : .japanese
            }
        }
    }
}

struct FAQRowView: View {
    let item: FAQItem
    let language: InfoLanguage
    let isExpanded: Bool
    let maxWidth: CGFloat
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Question bar
            Button(action: onTap) {
                HStack(spacing: 12) {
                    Text(item.question[language] ?? "")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Spacer(minLength: 4)
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.white)
                        .font(.system(size: 14, weight: .bold))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .frame(maxWidth: maxWidth)
                .background(Color.blue.opacity(0.8))
                .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Answer (expandable)
            if isExpanded {
                Text(item.answer[language] ?? "")
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(14)
                    .frame(maxWidth: maxWidth, alignment: .leading)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(10)
                    .padding(.top, 4)
            }
        }
    }
}
