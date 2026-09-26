class PredefinedSub {
  final String name;
  final String price;
  final String cycle;
  final String category;

  const PredefinedSub({
    required this.name,
    required this.price,
    required this.cycle,
    required this.category,
  });
}

const List<PredefinedSub> predefinedSubs = [
  // ENTERTAINMENT
  PredefinedSub(
    name: 'Netflix',
    price: '£15.49',
    cycle: 'Monthly',
    category: 'Entertainment',
  ),
  PredefinedSub(
    name: 'Disney+',
    price: '£7.99',
    cycle: 'Monthly',
    category: 'Entertainment',
  ),
  PredefinedSub(
    name: 'Amazon Prime',
    price: '£8.99',
    cycle: 'Monthly',
    category: 'Entertainment',
  ),
  PredefinedSub(
    name: 'YouTube Premium',
    price: '£12.99',
    cycle: 'Monthly',
    category: 'Entertainment',
  ),
  PredefinedSub(
    name: 'Apple TV+',
    price: '£8.99',
    cycle: 'Monthly',
    category: 'Entertainment',
  ),
  PredefinedSub(
    name: 'Paramount+',
    price: '£6.99',
    cycle: 'Monthly',
    category: 'Entertainment',
  ),
  PredefinedSub(
    name: 'HBO Max',
    price: '£9.99',
    cycle: 'Monthly',
    category: 'Entertainment',
  ),
  PredefinedSub(
    name: 'Crunchyroll',
    price: '£5.99',
    cycle: 'Monthly',
    category: 'Entertainment',
  ),

  // MUSIC
  PredefinedSub(
    name: 'Spotify',
    price: '£9.99',
    cycle: 'Monthly',
    category: 'Music',
  ),
  PredefinedSub(
    name: 'Apple Music',
    price: '£10.99',
    cycle: 'Monthly',
    category: 'Music',
  ),
  PredefinedSub(
    name: 'YouTube Music',
    price: '£10.99',
    cycle: 'Monthly',
    category: 'Music',
  ),
  PredefinedSub(
    name: 'Amazon Music',
    price: '£10.99',
    cycle: 'Monthly',
    category: 'Music',
  ),
  PredefinedSub(
    name: 'TIDAL',
    price: '£10.99',
    cycle: 'Monthly',
    category: 'Music',
  ),

  // AI
  PredefinedSub(
    name: 'ChatGPT Plus',
    price: '£20.00',
    cycle: 'Monthly',
    category: 'AI',
  ),
  PredefinedSub(
    name: 'Claude Pro',
    price: '£18.00',
    cycle: 'Monthly',
    category: 'AI',
  ),
  PredefinedSub(
    name: 'Google AI Pro',
    price: '£18.99',
    cycle: 'Monthly',
    category: 'AI',
  ),
  PredefinedSub(
    name: 'Perplexity Pro',
    price: '£17.00',
    cycle: 'Monthly',
    category: 'AI',
  ),

  // SOFTWARE
  PredefinedSub(
    name: 'Adobe',
    price: '£19.97',
    cycle: 'Monthly',
    category: 'Software',
  ),
  PredefinedSub(
    name: 'Microsoft 365',
    price: '£8.99',
    cycle: 'Monthly',
    category: 'Software',
  ),
  PredefinedSub(
    name: 'Canva',
    price: '£10.99',
    cycle: 'Monthly',
    category: 'Software',
  ),
  PredefinedSub(
    name: 'Notion',
    price: '£7.50',
    cycle: 'Monthly',
    category: 'Software',
  ),
  PredefinedSub(
    name: 'Dropbox',
    price: '£9.99',
    cycle: 'Monthly',
    category: 'Software',
  ),

  // CLOUD STORAGE
  PredefinedSub(
    name: 'Google One',
    price: '£1.59',
    cycle: 'Monthly',
    category: 'Cloud Storage',
  ),
  PredefinedSub(
    name: 'iCloud',
    price: '£0.99',
    cycle: 'Monthly',
    category: 'Cloud Storage',
  ),
  PredefinedSub(
    name: 'OneDrive',
    price: '£1.99',
    cycle: 'Monthly',
    category: 'Cloud Storage',
  ),

  // GAMING
  PredefinedSub(
    name: 'Xbox Game Pass',
    price: '£14.99',
    cycle: 'Monthly',
    category: 'Gaming',
  ),
  PredefinedSub(
    name: 'PlayStation Plus',
    price: '£6.99',
    cycle: 'Monthly',
    category: 'Gaming',
  ),
  PredefinedSub(
    name: 'Nintendo Switch Online',
    price: '£3.49',
    cycle: 'Monthly',
    category: 'Gaming',
  ),

  // FITNESS
  PredefinedSub(
    name: 'Strava',
    price: '£8.99',
    cycle: 'Monthly',
    category: 'Fitness',
  ),
  PredefinedSub(
    name: 'Peloton',
    price: '£24.99',
    cycle: 'Monthly',
    category: 'Fitness',
  ),

  // NEWS & READING
  PredefinedSub(
    name: 'The New York Times',
    price: '£17.00',
    cycle: 'Monthly',
    category: 'News & Reading',
  ),
  PredefinedSub(
    name: 'The Guardian',
    price: '£12.00',
    cycle: 'Monthly',
    category: 'News & Reading',
  ),
  PredefinedSub(
    name: 'LinkedIn Premium',
    price: '£39.99',
    cycle: 'Monthly',
    category: 'News & Reading',
  ),
  PredefinedSub(
    name: 'Amazon Kindle Unlimited',
    price: '£9.49',
    cycle: 'Monthly',
    category: 'News & Reading',
  ),

  // BILLS
  PredefinedSub(
    name: 'Electricity',
    price: '£100.00',
    cycle: 'Monthly',
    category: 'Bills',
  ),
  PredefinedSub(
    name: 'Gas',
    price: '£70.00',
    cycle: 'Monthly',
    category: 'Bills',
  ),
  PredefinedSub(
    name: 'Water',
    price: '£40.00',
    cycle: 'Monthly',
    category: 'Bills',
  ),
  PredefinedSub(
    name: 'Council Tax',
    price: '£150.00',
    cycle: 'Monthly',
    category: 'Bills',
  ),
  PredefinedSub(
    name: 'Broadband',
    price: '£35.00',
    cycle: 'Monthly',
    category: 'Bills',
  ),
  PredefinedSub(
    name: 'Mobile Phone',
    price: '£30.00',
    cycle: 'Monthly',
    category: 'Bills',
  ),
  PredefinedSub(
    name: 'TV Licence',
    price: '£14.00',
    cycle: 'Monthly',
    category: 'Bills',
  ),
  PredefinedSub(
    name: 'Rent',
    price: '£1200.00',
    cycle: 'Monthly',
    category: 'Bills',
  ),
  PredefinedSub(
    name: 'Mortgage',
    price: '£1200.00',
    cycle: 'Monthly',
    category: 'Bills',
  ),
  PredefinedSub(
    name: 'Home Insurance',
    price: '£25.00',
    cycle: 'Monthly',
    category: 'Bills',
  ),
  PredefinedSub(
    name: 'Car Insurance',
    price: '£80.00',
    cycle: 'Monthly',
    category: 'Bills',
  ),
  PredefinedSub(
    name: 'Life Insurance',
    price: '£20.00',
    cycle: 'Monthly',
    category: 'Bills',
  ),
  PredefinedSub(
    name: 'Health Insurance',
    price: '£50.00',
    cycle: 'Monthly',
    category: 'Bills',
  ),
  PredefinedSub(
    name: 'Road Tax',
    price: '£15.00',
    cycle: 'Monthly',
    category: 'Bills',
  ),
  PredefinedSub(
    name: 'Parking',
    price: '£50.00',
    cycle: 'Monthly',
    category: 'Bills',
  ),
  PredefinedSub(
    name: 'Gym',
    price: '£30.00',
    cycle: 'Monthly',
    category: 'Bills',
  ),
  PredefinedSub(
    name: 'Other Bill',
    price: '£0.00',
    cycle: 'Monthly',
    category: 'Bills',
  ),
];