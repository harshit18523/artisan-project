enum Language { en, hi }

class NavLabels {
  final String home, catalog, growth, support;
  const NavLabels({
    required this.home,
    required this.catalog,
    required this.growth,
    required this.support,
  });
}

class DashboardStrings {
  // Home
  final String addProductTitle, addProductSubtitle, addButtonLabel;
  final String overview, salesLabel, productsLabel;
  final String recentOrders, orderStatus, whatsapp;

  // Catalog
  final String catalogTitle, addNewProduct;
  final String editVoiceInfo, completeListing;
  final String statusLive, statusDraft;

  // Growth
  final String growthTitle, darkModeLabel;
  final String revenueLabel, trendLabel;
  final String chartTitle, peakLabel;
  final String totalOrdersLabel, avgOrderLabel;

  // Help / Support
  final String supportTitle, supportTitleAlt;
  final String voiceHelpTitle, voiceHelpSubtitle;
  final String listeningStatus, processingStatus, voiceStopSubmit;
  final String voiceAnswerTitle, voicePlay, voicePause, voiceTryAgain;
  final String voiceErrorMic, voiceErrorNetwork, voiceErrorGeneric;
  final String whatsappHelpTitle, whatsappHelpText;
  final String tutorialTitle, tutorialText, playLabel;
  final String callTitle, callNumber;

  // Shipped modal. [shippedTitle] contains a `{id}` placeholder for the order id.
  final String shippedTitle, shippedPill;
  final String buyerLabel, orderLabel;
  final String shareTracking, done;

  // New order toast. The order summary line is built from the real order.
  final String toastTitle, accept;

  final NavLabels nav;

  const DashboardStrings({
    required this.addProductTitle, required this.addProductSubtitle, required this.addButtonLabel,
    required this.overview, required this.salesLabel, required this.productsLabel,
    required this.recentOrders, required this.orderStatus, required this.whatsapp,
    required this.catalogTitle, required this.addNewProduct,
    required this.editVoiceInfo, required this.completeListing,
    required this.statusLive, required this.statusDraft,
    required this.growthTitle, required this.darkModeLabel,
    required this.revenueLabel, required this.trendLabel,
    required this.chartTitle, required this.peakLabel,
    required this.totalOrdersLabel, required this.avgOrderLabel,
    required this.supportTitle, required this.supportTitleAlt,
    required this.voiceHelpTitle, required this.voiceHelpSubtitle,
    required this.listeningStatus, required this.processingStatus, required this.voiceStopSubmit,
    required this.voiceAnswerTitle, required this.voicePlay, required this.voicePause,
    required this.voiceTryAgain, required this.voiceErrorMic,
    required this.voiceErrorNetwork, required this.voiceErrorGeneric,
    required this.whatsappHelpTitle, required this.whatsappHelpText,
    required this.tutorialTitle, required this.tutorialText, required this.playLabel,
    required this.callTitle, required this.callNumber,
    required this.shippedTitle, required this.shippedPill,
    required this.buyerLabel, required this.orderLabel,
    required this.shareTracking, required this.done,
    required this.toastTitle, required this.accept,
    required this.nav,
  });
}

const kStrings = <Language, DashboardStrings>{
  Language.en: DashboardStrings(
    addProductTitle: 'Snap to Add Product',
    addProductSubtitle: 'Take a photo. AI will do the rest.',
    addButtonLabel: 'Add a product using your camera',
    overview: 'Business Overview',
    salesLabel: "Today's Sales",
    productsLabel: 'Active Products',
    recentOrders: 'Recent Orders',
    orderStatus: 'New order',
    whatsapp: 'Manage on WhatsApp',
    catalogTitle: 'My Products',
    addNewProduct: 'Add New Product',
    editVoiceInfo: 'Edit Voice Info',
    completeListing: 'Complete Listing',
    statusLive: 'Live on ONDC',
    statusDraft: 'Draft',
    growthTitle: 'Business Growth',
    darkModeLabel: 'Dark mode',
    revenueLabel: 'Earned this month',
    trendLabel: 'this week',
    chartTitle: 'Weekly Earnings',
    peakLabel: 'Best day',
    totalOrdersLabel: 'Total Orders',
    avgOrderLabel: 'Avg. Order Value',
    supportTitle: 'Need Help?',
    supportTitleAlt: 'सहायता',
    voiceHelpTitle: 'Ask AI Assistant',
    voiceHelpSubtitle: 'Tap to speak your question in Hindi or English',
    listeningStatus: 'Listening...',
    processingStatus: 'Thinking...',
    voiceStopSubmit: 'Stop & Submit',
    voiceAnswerTitle: 'AI Answer',
    voicePlay: 'Play answer',
    voicePause: 'Pause',
    voiceTryAgain: 'Try Again',
    voiceErrorMic: "We couldn't access your microphone. Please allow mic access and try again.",
    voiceErrorNetwork: "We couldn't reach the AI assistant. Please check your internet and try again.",
    voiceErrorGeneric: 'Something went wrong. Please try again.',
    whatsappHelpTitle: 'Chat on WhatsApp Support',
    whatsappHelpText: 'Get 24/7 instant help on WhatsApp',
    tutorialTitle: 'Audio Tutorial: How to sell on ONDC',
    tutorialText: '4 min listen · Hindi & English',
    playLabel: 'Play audio tutorial',
    callTitle: 'Call Artisan Support Helpline',
    callNumber: '1800-HANDORA',
    shippedTitle: 'Order {id} Shipped!',
    shippedPill: 'Shipped',
    buyerLabel: 'Buyer',
    orderLabel: 'Order',
    shareTracking: 'Share Tracking on WhatsApp',
    done: 'Done',
    toastTitle: 'New Order Received!',
    accept: 'Accept',
    nav: NavLabels(home: 'Home', catalog: 'Catalog', growth: 'Growth', support: 'Help'),
  ),

  Language.hi: DashboardStrings(
    addProductTitle: 'फोटो खींचकर प्रोडक्ट जोड़ें',
    addProductSubtitle: 'बस एक फोटो लें, AI बाकी काम संभाल लेगा।',
    addButtonLabel: 'कैमरे से नया उत्पाद जोड़ें',
    overview: 'व्यापार का हाल',
    salesLabel: 'आज की बिक्री',
    productsLabel: 'चालू उत्पाद',
    recentOrders: 'नए ऑर्डर',
    orderStatus: 'नया ऑर्डर',
    whatsapp: 'WhatsApp पर देखें',
    catalogTitle: 'मेरे उत्पाद',
    addNewProduct: 'नया उत्पाद जोड़ें',
    editVoiceInfo: 'बोलकर बदलें',
    completeListing: 'लिस्टिंग पूरी करें',
    statusLive: 'ONDC पर लाइव',
    statusDraft: 'अधूरा',
    growthTitle: 'कमाई का हाल',
    darkModeLabel: 'डार्क मोड',
    revenueLabel: 'इस महीने की कमाई',
    trendLabel: 'इस हफ़्ते',
    chartTitle: 'हफ़्ते की कमाई',
    peakLabel: 'सबसे अच्छा दिन',
    totalOrdersLabel: 'कुल ऑर्डर',
    avgOrderLabel: 'औसत ऑर्डर',
    supportTitle: 'सहायता',
    supportTitleAlt: 'Need Help?',
    voiceHelpTitle: 'AI असिस्टेंट से पूछें',
    voiceHelpSubtitle: 'बोलकर अपनी समस्या या सवाल बताएं',
    listeningStatus: 'सुन रहा हूँ...',
    processingStatus: 'सोच रहा हूँ...',
    voiceStopSubmit: 'रोकें और भेजें',
    voiceAnswerTitle: 'AI का जवाब',
    voicePlay: 'जवाब सुनें',
    voicePause: 'रोकें',
    voiceTryAgain: 'फिर कोशिश करें',
    voiceErrorMic: 'माइक्रोफ़ोन नहीं खुल पाया। कृपया माइक की अनुमति दें और दोबारा कोशिश करें।',
    voiceErrorNetwork: 'AI असिस्टेंट से संपर्क नहीं हो पाया। कृपया इंटरनेट जाँचें और दोबारा कोशिश करें।',
    voiceErrorGeneric: 'कुछ गड़बड़ हो गई। कृपया दोबारा कोशिश करें।',
    whatsappHelpTitle: 'WhatsApp पर बात करें',
    whatsappHelpText: '24/7 तुरंत मदद पाएँ',
    tutorialTitle: 'ऑडियो गाइड: ONDC पर कैसे बेचें',
    tutorialText: '4 मिनट · हिंदी और अंग्रेज़ी',
    playLabel: 'ऑडियो गाइड सुनें',
    callTitle: 'कारीगर हेल्पलाइन पर कॉल करें',
    callNumber: '1800-HANDORA',
    shippedTitle: 'ऑर्डर {id} भेज दिया!',
    shippedPill: 'भेजा गया',
    buyerLabel: 'ख़रीदार',
    orderLabel: 'ऑर्डर',
    shareTracking: 'WhatsApp पर ट्रैकिंग भेजें',
    done: 'ठीक है',
    toastTitle: 'नया ऑर्डर आया!',
    accept: 'स्वीकारें',
    nav: NavLabels(home: 'होम', catalog: 'सामान', growth: 'कमाई', support: 'मदद'),
  ),
};
