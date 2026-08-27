import 'package:test/test.dart';
import 'package:wb_annatation/wb_annatation.dart';

void main() {
  const mapping = WbTopicMapping(
    inputs: {'alias/temp/on': 'dev_a/temp/on'},
    outputs: {'dev_a/lamp/on': 'alias/lamp/on'},
  );

  group('WbTopicMapping.resolveInputTopic', () {
    test('алиас → канонический топик', () {
      expect(mapping.resolveInputTopic('alias/temp/on'), 'dev_a/temp/on');
    });

    test('неизвестный топик без изменений', () {
      expect(mapping.resolveInputTopic('dev_a/temp/on'), 'dev_a/temp/on');
    });
  });

  group('WbTopicMapping.expandOutputTopics', () {
    test('канонический топик → канонический + алиас', () {
      expect(
        mapping.expandOutputTopics('dev_a/lamp/on'),
        ['dev_a/lamp/on', 'alias/lamp/on'],
      );
    });

    test('топик без маппинга → только исходный', () {
      expect(mapping.expandOutputTopics('dev_a/temp/on'), ['dev_a/temp/on']);
    });
  });

  group('WbTopicMapping.inputSubscriptionTopics', () {
    test('возвращает ключи inputs', () {
      expect(mapping.inputSubscriptionTopics, ['alias/temp/on']);
    });

    test('пустой маппинг → пустой список', () {
      expect(
        const WbTopicMapping().inputSubscriptionTopics,
        isEmpty,
      );
    });
  });
}
