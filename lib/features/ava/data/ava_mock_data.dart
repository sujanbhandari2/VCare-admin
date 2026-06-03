import '../domain/entities/ava_message.dart';

class AvaMockData {
  AvaMockData._();

  static final seedMessages = <AvaMessage>[
    AvaMessage(
      id: 'a1',
      sender: AvaSender.ava,
      body:
          "Hi Alex 👋 I'm AVA, your Advocate Virtual Assistant. I can help you find providers, estimate costs, explain benefits, or connect you with your advocate. What's on your mind?",
      createdAt: DateTime.now(),
    ),
  ];

  static const suggestions = [
    'Find an in-network dentist near me',
    'Estimate cost of an MRI',
    'What does my plan cover?',
    'Schedule a call with my advocate',
  ];

  static const mockReply =
      "Got it — I'm pulling that up for you. (Mock response — AVA will be powered by Lovable Cloud once enabled.)";
}
