/// PracticeConfig - Central configuration for all meditation practices and categories
/// 
/// Direct translation from PWA's PracticeConfig.js with all meditation practices,
/// categories, colors, and helper functions. Provides static configuration and
/// lookup utilities for practice categorization and metadata.

library;

import 'dart:ui';

class PracticeConfig {
  /// Central configuration object for all meditation practices
  /// Structure: categoryKey -> PracticeCategory with practices
  static const Map<String, Map<String, dynamic>> practiceConfig = {
    "mindfulness": {
      "name": "Mindfulness",
      "practices": {
        "Mindfulness of the Breathing": {
          "info": "First note the hindrance (e.g., \"Desire, Desire\"). If it persists, investigate by observing its manifestation in the body - tension, tightness, etc. Observe without feeding the hindrance until it passes."
        },
        "Working with Physical Sensations": {
          "info": "First treat like wandering thoughts. If aversion develops, observe the sensation's characteristics. When aversion is strong, observe its physical manifestations throughout the body. Work gently within your limits."
        }
      }
    },
    "compassion": {
      "name": "Compassion/Lovingkindness",
      "practices": {
        "Basic Compassion Lovingkindness": {
          "info": "Consider a person and their difficulties. Let Compassion arise, and then a Lovingkindess wish.\n\n\"May _______ be able to learn, practice and develop methods, techniques and tools of mental development, so that _______ can cope with, understand, accept and\novercome the difficulties and challenges of life. May _______ find Peace of Mind.\"\n\n\"May _______ be able to let go of anger, fear, worry and ignorance. May _______ also have patience, courage, wisdom and determination to meet and\novercome difficulties and problems, challenges of life. May _______ find Peace of Mind.\""
        },
        "Diffusing/Defusing (D/D)": {
          "info": "Take an existing unpleasant emotion for contemplation. Open to the Dukkha. \nWe can then universalize it by opening to vivid examples of humans or other living beings who may experience these emotions intensely. \nTrying to open out & have Compassion/Lovingkindness to them. e.g. aloneness, rejection. \nWhat other Living Beings may be experiencing this?\n\nA systematic way of doing the DD:\nFirst part is to start with yourself, then consider someone else, with similar Dukkha who is the same age and same sex, then same age & opposite sex, then add 10 years and both sexes, then go down 10 years and both sexes, then up 20, down 20 and continuing until we have gone down to little children and up to ~100-year-olds.\nIn the second part of the meditation, use your own age and sex.\nConsider many people similar to you but gradually imagine their Dukkha getting more and more intense.\nThe first part of this meditation shows us that we are not alone with our Dukkha. Many people all different ages experience the same types of Dukkha. This helps us to know that it is not just \"me, me, me, I am the only one who has this Dukkha!\"\nThe second part of this DD Compassion/Lovingkindness meditation shows us that our Dukkha is not so big, if we compare it to others. This helps us greatly to let go of our attachment to it."
        },
        "Forgiveness Meditation": {
          "info": "Systematic practice for self-forgiveness and forgiving others. Analyze past actions objectively, understanding the causes, then forgive with phrases like \"I forgive the person I was.\""
        },
        "Going Through Your Life": {
          "info": "Start as young as you can remember at home. Think of an occasion where you were with your family. Give yourself a Compassion/Lovingkindness wish. Give your family relatives a Compassion/Lovingkindness wish.\n\nThen at school, kindergarten, pre-school, etc. Think of an occasion where you were doing something with the others. Give yourself a Compassion/Lovingkindness wish. Give your teacher & other students a Compassion/Lovingkindness wish.\n\nThen outside of home or school. Think of an occasion where you were doing something with the others, probably sports or music, etc. \nGive yourself a Compassion/Lovingkindness wish. Give the others a Compassion/Lovingkindness wish.\n\nThen one year at a time, first your home, then school or work, then outside activities. Continue until today."
        },
        "By Age": {
          "info": "Choose a particular age in your life, give compassion to yourself at that age, then universalize to others of the same age doing similar activities."
        },
        "Groups by Countries": {
          "info": "Systematically go through groups of countries, then humanity as a whole, then self as part of humanity, then self."
        },
        "Waking Up Practice": {
          "info": "Identify with real situations of others waking up as different people, universalizing the experience and developing compassion."
        },
        "Material Objects Reflection": {
          "info": "Reflect on an object's dependent arising nature. Trace to origin, consider beings that suffered to make it. Develop compassion for all."
        },
        "Classify by Number of Legs": {
          "info": "Systematic classification:  no legs, 1 leg, 2 legs, 3 legs, 4 legs, 5, 6, 7, 8,... more than 8 legs, beings with wings, in the ocean, unseen beings. C/L for all."
        },
        "Before Going to Sleep": {
          "info": "Systematic way:\nC/L to person you were in the day\nClosest relative\nAll living beings met in the day\nA group people from your past\nA group people from world (e.g. doctors, soldiers etc.)\nAll beings collectively"
        },
        "1-10-11-1": {
          "info": "Imagine you are in town and you meet another person your same age and sex. Then you start having a conversation with them. As they talk, though, they are very sad and upset. They talk about all of the difficulties that they have had in their life and how bad it has all been. All of these difficulties are just the same as you have had. Yet they are feeling very sad and upset. Can you have Compassion/Lovingkindness for them?\n\nTheir problems are similar to your own. They are very sad and upset.\nWish them a Compassion/Lovingkindness wish.\n\nNow as you are still in town you go to a restaurant to eat and you meet that same person again. They are sitting and eating with nine other people, similar age and the same sex. But they are all sad and upset talking about the hardships and difficulties they have had. And all these hardships and difficulties are similar to those you have had. Yet they are feeling very sad and upset. Can you have Compassion/Lovingkindness for these ten people, similar age and sex to you, with similar life difficulties?\n\nTheir problems are similar to your own. They are very sad and upset.\nWish these ten people a Compassion/Lovingkindness wish.\n\nNow you join them. Eleven people, all a similar age and sex. All with similar difficulties and challenges in life. Can you have Compassion/Lovingkindness for all eleven of these people -- as a group of people -- with you as one of them?\n\nAll of you have similar difficulties and challenges. Wish all eleven people a Compassion/Lovingkindness wish.\n\nNow let the ten people go away. And you are left with just yourself. A human being with your own difficulties and challenges. Can you have Compassion/Lovingkindness for yourself?\n\nAnother person in the world with your own difficulties and challenges.\nWish yourself a Compassion/Lovingkindness wish."
        }
      }
    },
    "sympatheticJoy": {
      "name": "Sympathetic Joy",
      "practices": {
        "Basic Sympathetic Joy": {
          "info": "In times of discouragement, may _________ be able to remember my/their good qualities. Take Joy with them, in the gradual awakening and my inner potential. Feeling Joy in the teachings, may it give me/them a refuge, giving me/them confidence and energy to continue.\n\nMay ________ feel happiness within and be able to continue in this way. May ________ be able to make more good decisions in my/their life. And, at moments, if ________ fail in some of them, may ________ remember the times when my/their resolutions were strong. May this make ________ happy so I/they can then try again to succeed in my/their resolutions. This would bring more happiness and joy.\n\nYourself, parents, teachers, people who help others, who develop their good qualities, etc"
        }
      }
    },
    "equanimity": {
      "name": "Equanimity",
      "practices": {
        "Equanimity Basic Practice": {
          "info": "Please reflect that everything that comes to ________ is the result of causes that have preceded it.\n\n________ is the owner of their own Kamma. May this understanding help give me more Equanimity, realizing that they will receive the results of their own Kamma, and I may not have the power to change this."
        }
      }
    },
    "wiseReflection": {
      "name": "Wise Reflection",
      "practices": {
        "Dedication of Direction & Merits": {
          "info": "Dedication of Direction\nMay I take this opportunity to rededicate my intention to develop the Paramis as much as I can, so that I can be of the most possible benefit to myself and all\nbeings.\n\nDedication of Merits\nThis is another practice which can help us develop more Right Understanding and Right Intention. Briefly speaking, it is taught that we can share the benefit of any good Kamma we have done with other living beings. We encourage you to end each day with a similar dedication. For those of you who are really keen, you could end each formal session with the dedication.\nThis dedication helps to give a sense of contentment and joy with your efforts. You remember that you are not doing this practice just for yourself and your own peace, but also for the benefit and welfare of all beings - through Compassion for the world.\nMay what I have done, to help purify the mind, be of some help to benefit all beings."
        },
        "Five/Seven Reflections": {
          "info": "1) How fortunate I am, 2) Death, 3) Actions and Results, 4) Dukkha, 5) Impermanence, 6) No problems only challenges, 7) Compassion and Equanimity.\n\nThese are some suggestions on how to do the Reflection meditations in long form\n\nWith regard to \"How fortunate you are\" reflection:\nSimply reflect on all the different ways that you are fortunate, material and mental. Watch out for the word \"but\" - it is not part of this reflection.\n\nWith regard to Dukkha (unsatisfactoriness) reflection:\nOne way to reflect is to think of every single type of Dukkha that you can imagine. Using systems helps with this, such as:\n**the alphabet with occupations: What types of Dukkha can airplane pilots experience?, bankers, cooks, doctors, etc.\n**body parts: What kinds of Dukkha can occur in the toes?, feet, legs, hips, etc.; inside also like cancer, diarrhea, etc.\n**ages: from 1 to 100, What kinds of Dukkha can come for babies, one year olds, two, etc.\n**alphabet with mental Dukkha: anger, boredom, craving, etc.\n\nWith regard to Death & Impermanence reflection:\nWe could do similar to the Dukkha reflection and go through systems considering every different way in which one could die.\n\nWith regard to the reflection on \"Actions & the results of Actions\":\nOne way of reflecting can be what we call \"Inward and Outward\".\nConcerning \"Actions & the results of Actions\"; Inward is where we look into our past and consider an experience and the results of it. If it was a beneficial action and beneficial results then we try to remember it so we can repeat it in the future, should a similar experience come about. If it was an unbeneficial action and unbeneficial results, then we try to understand how we could have done it better. We could also consider what others would have done in a similar event. Especially thinking about what people we respect would have done.\nOutward is where we look at others and things which we have read about or seen that have happened. Then we contemplate how the actions were beneficial or unbeneficial as above. And we consider what we would do in a similar situation. By reflecting in these ways, we try to develop the understanding of how to react in a wise and beneficial way in the future.\n\nWith regard to the reflection, \"the Relationship of Compassion and Equanimity\":\nThe reflection on \"the Relationship of Compassion and Equanimity\" is basically a smaller part of the above. But in this reflection we try to contemplate about situations in which a balance of Compassion and Equanimity was needed. We try to think of times when it was in balance and times when it was not and reflect how to increase this balance or how to correct the imbalance.\n\nAgain this can be Inward and Outward. An outward example of balanced Compassion and Equanimity is Mother Theresa's life story. When she went to India she was filled with Compassion and kept it balanced with Equanimity. She did not allow her Compassion to go into grief nor go into anger. An example of unbalanced Compassion and Equanimity is the Oklahoma (USA) bombing of a government building some years ago. Supposedly the men who did it had some sort of compassion for the USA and wanted to \"wake-up, etc.\" the American people. However their compassion went strongly into aversion.\n\nPS. These various systems can also work with the Compassion/Lovingkindness meditation."
        },
        "Five Daily Recollections": {
          "info": "Traditional contemplations: \n\nI am of the nature to decay\nI have not gone beyond decay\nI am of the nature to be diseased\nI have not gone beyond disease\nI am of the nature to die\nI have not gone beyond death\nAll that is mine, dear and delightful, will change and vanish\nI am the owner of my Kamma\nI am the heir to my Kamma\nI am born of my Kamma\nI am related to my Kamma\nI abide supported by my Kamma\nOf whatever Kamma I shall do, whether wholesome or unwholesome, of that I will be the heir"
        },
        "Death Reflection": {
          "info": "Think of _______ who has died. Picture _______ alive and doing something.\n\nWhatever you can imagine, maybe you only saw a photo of them so imagine them talking, walking, sitting, whatever. Don't get involved in a story about them. Just picture _______ alive, doing something.\n\nNow remember that they are dead, gone, no longer a part of this world.\n\nBring this awareness to yourself, that you, too, will definitely die one day.\n\n\"Verily, also, my own body is of the same nature, such it will become and will not escape it.\"\n\nMay they be able to have the opportunity to develop the mind. But if death comes unexpectedly, may they be able to have contentment or peace. May they use their\nprecious opportunity to develop beneficial qualities."
        },
        "Ten Paramis": {
          "info": "Generosity, Morality, Renunciation, Wisdom, Energy, Patience, Truthfulness, Determination, Compassion/Lovingkindness, Equanimity.\n\nSince starting my Meditation/Mental Development practice,\nhave I grown in ________?\nHow much have I grown in ________?\nReflecting upon my ________, let me consider just how I feel about my development of ________?\nIs there more I can grow in ________?\nWhat can I do in my life to help my level of ________ to grow?"
        },
        "Eight Worldly Dhammas": {
          "info": "Reflect on attachment to four pairs: Praise/Blame, Fame/Obscurity, Gain/Loss, Pleasure/Pain."
        },
        "Origination and Dissolution": {
          "info": "Think of an external inanimate material object that you like very much - something you feel you are quite attached in some way, something you use a lot or that you consider yours.\n\nNow please trace this object back in time to see its source. Consider how it came to you.\n\nWhere was this object found, given to you or sold?\n\nWhere was this object made?\n\nNow please break it down into the four elements of earth, water, wind and fire?\n\nHow did the elements get to the place where the object was created?\n\nWhat form were the elements in then?\n\nWere they dug up from somewhere? - metal (earth), grown somewhere (plant) did they depend on the earth, water, wind and fire for that process?\n\nDid they come from Nature?\n\nWill this object that you like ever change or age?\n\nImagine it changing or aging\n\nWill the object ever cease to be in the form it is in now?\n\nWill the object return to Nature?\n\nCan you prevent this happening?\n\nIs the object then really yours?\n\nWho does it belong to?\n\nIs your body also composed of these four elements of earth, water, wind and fire?\n\nDid it also come from Nature?\n\nCan the body be separated from the four elements of Nature for very long and still survive in the form it is in now?\n\nHas the body ever changed or aged?\n\nImagine the body changing or aging?\n\nWill it return to Nature?\n\nCan you prevent this happening?\n\nCan the body ultimately be yours?"
        },
        "Food Reflection": {
          "info": "Three contemplations during meals: 1) Why do you eat? 2) How fortunate you are, 3) Difficulties in getting food to you."
        }
      }
    }
  };

  /// Color scheme for practice categories used in charts and UI
  static const Map<String, Color> categoryColors = {
    'mindfulness': Color(0xFF06B6D4),      // Cyan/teal
    'compassion': Color(0xFFEC4899),       // Pink
    'sympatheticJoy': Color(0xFFF59E0B),   // Amber/gold
    'equanimity': Color(0xFF8B5CF6),       // Purple
    'wiseReflection': Color(0xFF10B981),   // Emerald green
  };

  /// Available meditation postures
  static const List<String> postures = [
    'Sitting', 
    'Standing', 
    'Walking'
  ];

  /// Practice category lookup map for O(1) performance
  /// Built once on initialization, maps practice name -> category key
  static final Map<String, String> _practiceCategoryMap = _buildPracticeCategoryMap();

  /// Build reverse lookup map for practice categories
  /// Called once on initialization for O(1) lookups
  static Map<String, String> _buildPracticeCategoryMap() {
    final Map<String, String> map = {};
    
    for (final entry in practiceConfig.entries) {
      final categoryKey = entry.key;
      final category = entry.value;
      final practices = category['practices'] as Map<String, dynamic>;
      
      // Map direct practices (e.g., "Basic Compassion Lovingkindness" → "compassion")
      for (final practiceName in practices.keys) {
        map[practiceName] = categoryKey;
        
        // Handle hierarchical practices with subcategories
        final subcategories = practices[practiceName];
        if (subcategories is Map<String, dynamic>) {
          // Map each subcategory option to the parent category
          for (final options in subcategories.values) {
            if (options is List) {
              for (final option in options) {
                if (option is String) {
                  map[option] = categoryKey;
                }
              }
            }
          }
        }
      }
    }
    
    return map;
  }

  /// Get the category for a given practice name
  /// Uses pre-built map for O(1) lookup performance
  static String getCategoryForPractice(String practiceName) {
    return _practiceCategoryMap[practiceName] ?? 'wiseReflection';
  }

  /// Get practice info for a given practice name
  /// Returns the info string or null if not found
  static String? getPracticeInfo(String practiceName) {
    // Search through all categories for the practice
    for (final entry in practiceConfig.entries) {
      final category = entry.value;
      final practices = category['practices'] as Map<String, dynamic>;
      
      // Check direct practices
      if (practices.containsKey(practiceName)) {
        final practiceData = practices[practiceName];
        if (practiceData is Map<String, dynamic> && practiceData.containsKey('info')) {
          return practiceData['info'] as String?;
        }
      }
    }
    
    return null;
  }

  /// Get all practice names for a given category
  static List<String> getPracticesForCategory(String categoryKey) {
    final category = practiceConfig[categoryKey];
    if (category == null) return [];
    
    final practices = category['practices'] as Map<String, dynamic>;
    return practices.keys.toList();
  }

  /// Get all category keys
  static List<String> getAllCategories() {
    return practiceConfig.keys.toList();
  }

  /// Get human-readable category name
  static String getCategoryName(String categoryKey) {
    final category = practiceConfig[categoryKey];
    if (category == null) return categoryKey;
    return category['name'] as String? ?? categoryKey;
  }

  /// Get color for a category
  static Color getCategoryColor(String categoryKey) {
    return categoryColors[categoryKey] ?? const Color(0xFF6B7280); // Default gray
  }

  /// Check if a practice name exists in the configuration
  static bool practiceExists(String practiceName) {
    return _practiceCategoryMap.containsKey(practiceName);
  }

  /// Get all practice names across all categories
  static List<String> getAllPractices() {
    return _practiceCategoryMap.keys.toList();
  }
}