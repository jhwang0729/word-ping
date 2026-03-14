class DictionaryResponse {
  final String word;
  final String phonetic;
  final List<DictionaryMeaning> meanings;

  const DictionaryResponse({
    required this.word,
    required this.phonetic,
    required this.meanings,
  });

  factory DictionaryResponse.fromJsonList(List<dynamic> jsonList) {
    if (jsonList.isEmpty) {
      throw Exception('Empty response');
    }

    final firstEntry = jsonList[0] as Map<String, dynamic>;
    final word = firstEntry['word'] as String;

    // Find best phonetic: prefer one with text
    String phonetic = '';
    final phoneticField = firstEntry['phonetic'] as String?;
    final phonetics = firstEntry['phonetics'] as List<dynamic>? ?? [];

    if (phoneticField != null && phoneticField.isNotEmpty) {
      phonetic = phoneticField;
    } else {
      for (final p in phonetics) {
        final text = (p as Map<String, dynamic>)['text'] as String?;
        if (text != null && text.isNotEmpty) {
          phonetic = text;
          break;
        }
      }
    }

    // Collect all meanings across all entries
    final allMeanings = <DictionaryMeaning>[];
    for (final entry in jsonList) {
      final entryMap = entry as Map<String, dynamic>;
      final meanings = entryMap['meanings'] as List<dynamic>? ?? [];
      for (final m in meanings) {
        final meaningMap = m as Map<String, dynamic>;
        final partOfSpeech = meaningMap['partOfSpeech'] as String;
        final definitions = meaningMap['definitions'] as List<dynamic>? ?? [];
        for (final d in definitions) {
          final defMap = d as Map<String, dynamic>;
          allMeanings.add(DictionaryMeaning(
            partOfSpeech: partOfSpeech,
            definition: defMap['definition'] as String,
            example: defMap['example'] as String?,
          ));
        }
      }
    }

    return DictionaryResponse(
      word: word,
      phonetic: phonetic,
      meanings: allMeanings,
    );
  }
}

class DictionaryMeaning {
  final String partOfSpeech;
  final String definition;
  final String? example;

  const DictionaryMeaning({
    required this.partOfSpeech,
    required this.definition,
    this.example,
  });
}
