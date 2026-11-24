-- English names for every character, so English-locale players see English.
-- Also tidies data found while translating:
--   * trailing spaces in two names
--   * two duplicate words (deactivated, not deleted: rounds reference them)

alter table public.characters add column if not exists name_en text;

update public.characters set name = btrim(name) where name <> btrim(name);

update public.characters set is_active = false
where name in ('بيلكان', 'هالاند');

update public.characters c set name_en = v.en
from (values
  -- animals
  ('أخطبوط','Octopus'),('أرنب','Rabbit'),('أسد','Lion'),('باندا','Panda'),('بجعة','Swan'),
  ('بط','Duck'),('بطريق','Penguin'),('بعوضة','Mosquito'),('بقرة','Cow'),('بومة','Owl'),
  ('بيلكان','Pelican'),('بيليكان','Pelican'),('تمساح','Crocodile'),('ثعلب','Fox'),('جمل','Camel'),
  ('حرباء','Chameleon'),('حصان','Horse'),('حمار','Donkey'),('حمامة','Pigeon'),('خروف','Sheep'),
  ('خفاش','Bat'),('دب','Bear'),('دولفين','Dolphin'),('ديك','Rooster'),('ذئب','Wolf'),
  ('زرافة','Giraffe'),('سرطان البحر','Crab'),('سمكة','Fish'),('شمبانزي','Chimpanzee'),('ضفدع','Frog'),
  ('طاووس','Peacock'),('عصفور','Sparrow'),('غراب','Crow'),('فرس النهر','Hippo'),('فيل','Elephant'),
  ('قرد','Monkey'),('قرش','Shark'),('قنفذ','Hedgehog'),('كنغر','Kangaroo'),('كوالا','Koala'),
  ('نسر','Eagle'),('نمر','Tiger'),('وحيد القرن','Rhino'),
  -- clothes
  ('بالطو','Overcoat'),('بدلة','Suit'),('بنطلون','Trousers'),('بيجامة','Pajamas'),('تيشيرت','T-shirt'),
  ('جاكيت','Jacket'),('جزمة','Shoes'),('جلابية','Galabeya'),('جوانتي','Gloves'),('حزام','Belt'),
  ('ساعة إيد','Wristwatch'),('شبشب','Slippers'),('شراب','Socks'),('شنطة ضهر','Backpack'),('شورت','Shorts'),
  ('طاقية','Beanie'),('عباية','Abaya'),('فستان','Dress'),('قميص','Shirt'),('كاب','Cap'),
  ('كرافتة','Tie'),('كوتشي','Sneakers'),('كوفية','Scarf'),('مايوه','Swimsuit'),('نضارة شمس','Sunglasses'),
  -- countries
  ('أستراليا','Australia'),('ألمانيا','Germany'),('أمريكا','USA'),('إسبانيا','Spain'),('إنجلترا','England'),
  ('إيطاليا','Italy'),('الأرجنتين','Argentina'),('الأردن','Jordan'),('الإمارات','UAE'),('البرازيل','Brazil'),
  ('السعودية','Saudi Arabia'),('السودان','Sudan'),('الصين','China'),('العراق','Iraq'),('الكويت','Kuwait'),
  ('المغرب','Morocco'),('الهند','India'),('اليابان','Japan'),('اليمن','Yemen'),('تركيا','Turkey'),
  ('روسيا','Russia'),('سوريا','Syria'),('فرنسا','France'),('فلسطين','Palestine'),('قطر','Qatar'),
  ('كندا','Canada'),('كوريا الجنوبية','South Korea'),('لبنان','Lebanon'),('ليبيا','Libya'),('مصر','Egypt'),
  -- daily_products
  ('إسفنجة','Sponge'),('بطارية','Battery'),('ترمس','Thermos'),('جردل','Bucket'),('حقيبة','Bag'),
  ('زجاجة ماء','Water bottle'),('سائل غسيل أطباق','Dish soap'),('سلم','Ladder'),('شاحن موبايل','Phone charger'),('شامبو','Shampoo'),
  ('شريط لاصق','Tape'),('شمعة','Candle'),('صابون','Soap'),('صابون سائل لليد','Hand wash'),('طفاية حريق','Fire extinguisher'),
  ('عبوة مناديل مبللة','Wet wipes'),('علبة حفظ طعام','Food container'),('علبة كبريت','Matchbox'),('غسول وجه','Face wash'),('فرشاة أسنان','Toothbrush'),
  ('فوطة مطبخ','Kitchen towel'),('قفازات تنظيف','Cleaning gloves'),('قلم رصاص','Pencil'),('كريم حلاقة','Shaving cream'),('كريم مرطب','Moisturizer'),
  ('كيس تسوق','Shopping bag'),('كيس قمامة','Trash bag'),('لمبة','Light bulb'),('مروحة','Fan'),('مزيل عرق','Deodorant'),
  ('مسحوق غسيل','Laundry detergent'),('مشبك غسيل','Clothespin'),('مطهر','Disinfectant'),('معجون أسنان','Toothpaste'),('معطر جو','Air freshener'),
  ('مفتاح ربط','Wrench'),('مقص','Scissors'),('مكواة ملابس','Iron'),('ممسحة','Mop'),('مناديل','Tissues'),
  ('منشفة','Towel'),('منظف أرضيات','Floor cleaner'),('ورق تواليت','Toilet paper'),
  -- foods
  ('باستا','Pasta'),('برجر','Burger'),('بسبوسة','Basbousa'),('بيتزا','Pizza'),('تبولة','Tabbouleh'),
  ('حمص','Hummus'),('رز بلبن','Rice pudding'),('سمبوسة','Samosa'),('سوشي','Sushi'),('شاورما','Shawarma'),
  ('طعمية','Taameya'),('عصيدة','Aseeda'),('عيش بلدي','Baladi bread'),('فتة','Fatta'),('فتوش','Fattoush'),
  ('فطير مشلتت','Feteer meshaltet'),('فلافل','Falafel'),('فول','Ful medames'),('قطايف','Qatayef'),('كبسة','Kabsa'),
  ('كحك','Kahk'),('كشري','Koshari'),('كنافة','Kunafa'),('كنتاكي','Fried chicken'),('لقيمات','Luqaimat'),
  ('محشي','Mahshi'),('محلبية','Mahalabia'),('مسخن','Musakhan'),('مقلوبة','Maqluba'),('مكرونة بشاميل','Macaroni béchamel'),
  ('ملوخية','Molokhia'),('مناقيش','Manakish'),('مندي','Mandi'),('هريسة','Harissa'),('ورق عنب','Stuffed vine leaves'),
  -- football_players
  ('أليسون بيكر','Alisson Becker'),('أندريس كانتور','Andrés Cantor'),('أنطوان جريزمان','Antoine Griezmann'),('إبراهيموفيتش','Ibrahimović'),('إنييستا','Iniesta'),
  ('إيرلينج هالاند','Erling Haaland'),('بوكايو ساكا','Bukayo Saka'),('بول بوغبا','Paul Pogba'),('بيدري','Pedri'),('تشافي','Xavi'),
  ('توماس مولر','Thomas Müller'),('ثيري أنري','Thierry Henry'),('جانلويجي بوفون','Gianluigi Buffon'),('جود بيلينجهام','Jude Bellingham'),('حسام حسن','Hossam Hassan'),
  ('خافي هيرنانديز','Javier Hernández'),('ديدييه دروغبا','Didier Drogba'),('ديفيد بيكهام','David Beckham'),('رافينيا','Raphinha'),('روبرت ليفاندوفسكي','Robert Lewandowski'),
  ('روبرتو كارلوس','Roberto Carlos'),('رودري','Rodri'),('رونالدو البرازيلي','Ronaldo Nazário'),('رونالدينيو','Ronaldinho'),('زين الدين زيدان','Zinedine Zidane'),
  ('ستيفن جيرارد','Steven Gerrard'),('سيرجيو أغويرو','Sergio Agüero'),('سيرجيو راموس','Sergio Ramos'),('شيفتشينكو','Shevchenko'),('عمر مرموش','Omar Marmoush'),
  ('غاريث بيل','Gareth Bale'),('فرانك لامبارد','Frank Lampard'),('فيران توريس','Ferran Torres'),('فيرجيل فان دايك','Virgil van Dijk'),('فينيسيوس جونيور','Vinícius Júnior'),
  ('كاكا','Kaká'),('كريستيانو رونالدو','Cristiano Ronaldo'),('كريم بنزيما','Karim Benzema'),('كيفين دي بروين','Kevin De Bruyne'),('كيليان مبابي','Kylian Mbappé'),
  ('لوكا مودريتش','Luka Modrić'),('ليونيل ميسي','Lionel Messi'),('محمد أبو تريكة','Mohamed Aboutrika'),('محمد النني','Mohamed Elneny'),('محمد صلاح','Mohamed Salah'),
  ('محمود الخطيب','Mahmoud El Khatib'),('نيمار','Neymar'),('هالاند','Haaland'),('وين روني','Wayne Rooney'),('يامال','Lamine Yamal'),
  -- fruits_vegetables
  ('أناناس','Pineapple'),('باذنجان','Eggplant'),('بامية','Okra'),('برتقال','Orange'),('بروكلي','Broccoli'),
  ('بصل','Onion'),('بطاطس','Potato'),('بطيخ','Watermelon'),('بلح','Dates'),('تفاح','Apple'),
  ('توم','Garlic'),('تين','Fig'),('جزر','Carrot'),('جوافة','Guava'),('خس','Lettuce'),
  ('خوخ','Peach'),('خيار','Cucumber'),('ذرة','Corn'),('رمان','Pomegranate'),('طماطم','Tomato'),
  ('عنب','Grapes'),('فراولة','Strawberry'),('فلفل','Bell pepper'),('قرنبيط','Cauliflower'),('كمثرى','Pear'),
  ('كوسة','Zucchini'),('كيوي','Kiwi'),('ليمون','Lemon'),('مانجا','Mango'),('موز','Banana'),
  -- islamic_figures
  ('أبو بكر الصديق','Abu Bakr al-Siddiq'),('أبو هريرة','Abu Hurayrah'),('أنس بن مالك','Anas ibn Malik'),('ابن القيم','Ibn al-Qayyim'),('ابن تيمية','Ibn Taymiyyah'),
  ('ابن حجر العسقلاني','Ibn Hajar al-Asqalani'),('ابن رشد','Ibn Rushd (Averroes)'),('الإمام أبو حنيفة','Imam Abu Hanifa'),('الإمام أحمد بن حنبل','Imam Ahmad ibn Hanbal'),('الإمام البخاري','Imam al-Bukhari'),
  ('الإمام الشافعي','Imam al-Shafi''i'),('الإمام الغزالي','Imam al-Ghazali'),('الإمام مالك','Imam Malik'),('الإمام مسلم','Imam Muslim'),('الزبير بن العوام','Al-Zubayr ibn al-Awwam'),
  ('النووي','Al-Nawawi'),('بلال بن رباح','Bilal ibn Rabah'),('جابر بن عبد الله','Jabir ibn Abdullah'),('حمزة بن عبد المطلب','Hamza ibn Abd al-Muttalib'),('خالد بن الوليد','Khalid ibn al-Walid'),
  ('سعد بن أبي وقاص','Sa''d ibn Abi Waqqas'),('سعد بن معاذ','Sa''d ibn Mu''adh'),('سلمان الفارسي','Salman al-Farsi'),('صلاح الدين الأيوبي','Saladin'),('طارق بن زياد','Tariq ibn Ziyad'),
  ('طلحة بن عبيد الله','Talha ibn Ubaydullah'),('عائشة بنت أبي بكر','Aisha bint Abi Bakr'),('عبد الرحمن بن عوف','Abd al-Rahman ibn Awf'),('عبد الله بن عباس','Abdullah ibn Abbas'),('عثمان بن عفان','Uthman ibn Affan'),
  ('علي بن أبي طالب','Ali ibn Abi Talib'),('عمر بن الخطاب','Umar ibn al-Khattab'),('عمر بن عبد العزيز','Umar ibn Abd al-Aziz'),('عمرو بن العاص','Amr ibn al-As'),('فاطمة الزهراء','Fatima al-Zahra'),
  ('مالك بن أنس','Malik ibn Anas'),('محمد الفاتح','Mehmed the Conqueror'),('معاذ بن جبل','Mu''adh ibn Jabal'),('نور الدين زنكي','Nur al-Din Zengi'),('هارون الرشيد','Harun al-Rashid'),
  -- places
  ('أبو ظبي','Abu Dhabi'),('أسوان','Aswan'),('إسطنبول','Istanbul'),('الأهرامات','The Pyramids'),('الإسكندرية','Alexandria'),
  ('البحر الميت','The Dead Sea'),('الجزائر','Algiers'),('الخرطوم','Khartoum'),('الرياض','Riyadh'),('القاهرة','Cairo'),
  ('القدس','Jerusalem'),('الكعبة المشرفة','The Kaaba'),('المتحف المصري','The Egyptian Museum'),('المدينة المنورة','Medina'),('باريس','Paris'),
  ('برج إيفل','Eiffel Tower'),('برج خليفة','Burj Khalifa'),('برشلونة','Barcelona'),('بغداد','Baghdad'),('بيروت','Beirut'),
  ('تونس','Tunis'),('دبي','Dubai'),('روما','Rome'),('سيدني','Sydney'),('صنعاء','Sanaa'),
  ('طوكيو','Tokyo'),('عمان','Amman'),('لندن','London'),('مدريد','Madrid'),('مكة','Mecca'),
  ('ميلانو','Milan'),('نيويورك','New York'),
  -- professions
  ('بواب','Doorman'),('ترزي','Tailor'),('حلاق','Barber'),('خباز','Baker'),('دكتور','Doctor'),
  ('رائد فضاء','Astronaut'),('رجل إطفاء','Firefighter'),('ساعي بريد','Postman'),('سباك','Plumber'),('سواق تاكسي','Taxi driver'),
  ('شيف','Chef'),('صحفي','Journalist'),('صياد سمك','Fisherman'),('صيدلي','Pharmacist'),('طبيب أسنان','Dentist'),
  ('طيار','Pilot'),('ظابط شرطة','Police officer'),('قاضي','Judge'),('كهربائي','Electrician'),('مبرمج','Programmer'),
  ('محاسب','Accountant'),('محامي','Lawyer'),('مدرس','Teacher'),('مزارع','Farmer'),('مصور','Photographer'),
  ('ممرضة','Nurse'),('مهندس','Engineer'),('مهندس ديكور','Interior designer'),('ميكانيكي','Mechanic'),('نجار','Carpenter'),
  -- sports
  ('اسكواش','Squash'),('بلياردو','Billiards'),('بولينج','Bowling'),('تزلج على الجليد','Ice skating'),('تسلق الجبال','Mountain climbing'),
  ('تنس','Tennis'),('تنس طاولة','Table tennis'),('جري','Running'),('جمباز','Gymnastics'),('جولف','Golf'),
  ('رفع أثقال','Weightlifting'),('ركوب الأمواج','Surfing'),('ركوب الخيل','Horse riding'),('رماية','Archery'),('سباحة','Swimming'),
  ('سباق دراجات','Cycling'),('شطرنج','Chess'),('غطس','Diving'),('كاراتيه','Karate'),('كرة السلة','Basketball'),
  ('كرة الطائرة','Volleyball'),('كرة القدم','Football'),('كرة اليد','Handball'),('مصارعة','Wrestling'),('ملاكمة','Boxing'),
  -- transport
  ('أتوبيس','Bus'),('تاكسي','Taxi'),('تريلا','Truck'),('تلفريك','Cable car'),('توكتوك','Tuk-tuk'),
  ('جرار زراعي','Tractor'),('سفينة','Ship'),('سكوتر','Scooter'),('صاروخ','Rocket'),('طيارة','Airplane'),
  ('عجلة','Bicycle'),('عربية','Car'),('عربية إسعاف','Ambulance'),('عربية كارو','Horse cart'),('عربية مطافي','Fire truck'),
  ('غواصة','Submarine'),('قطار','Train'),('قطار سريع','High-speed train'),('مترو','Metro'),('مركب','Boat'),
  ('منطاد','Hot-air balloon'),('موتوسيكل','Motorcycle'),('ميكروباص','Minibus'),('هليكوبتر','Helicopter'),('يخت','Yacht')
) as v(ar, en)
where c.name = v.ar;
