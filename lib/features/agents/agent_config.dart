import 'package:flutter/material.dart';

enum AgentType { psychology, social, language, biological }

class AgentConfig {
  final AgentType type;
  final String name;
  final String subtitle;
  final String systemPrompt;
  final IconData icon;
  final Color color;

  const AgentConfig({
    required this.type,
    required this.name,
    required this.subtitle,
    required this.systemPrompt,
    required this.icon,
    required this.color,
  });
}

// The single source of truth for all 4 agent identities.
// Adding a 5th agent = adding one entry here. Nothing else changes.
const Map<AgentType, AgentConfig> kAgents = {
  AgentType.psychology: AgentConfig(
    type: AgentType.psychology,
    name: 'Psychology',
    subtitle: 'Anxiety & Withdrawal',
    icon: Icons.self_improvement,
    color: Color(0xFF7C6BDB),
    systemPrompt:
        'You are a grounded, empathetic psychological AI assistant for immigrants. '
        'The user is experiencing anxiety, homesickness, or withdrawal. '
        'Use grounding techniques, validate their emotions, and provide calming, '
        'bite-sized coping mechanisms. Do not give medical diagnoses.',
  ),

  AgentType.social: AgentConfig(
    type: AgentType.social,
    name: 'Social',
    subtitle: 'Isolation & Cultural Conflict',
    icon: Icons.people_outline,
    color: Color(0xFF4CAEEA),
    systemPrompt:
        'You are a cultural integration AI. '
        'The user is facing social isolation or a cultural misunderstanding. '
        'Explain the host country\'s social norms logically without judging the '
        'user\'s native culture. Provide actionable icebreakers and polite ways '
        'to handle conflict.',
  ),

  AgentType.language: AgentConfig(
    type: AgentType.language,
    name: 'Language',
    subtitle: 'Communication Avoidance',
    icon: Icons.translate,
    color: Color(0xFF4CAF82),
    systemPrompt:
        'You are a supportive linguistic AI. '
        'The user is afraid to speak due to a language barrier. '
        'Provide phonetic pronunciations, simple sentence structures, and '
        'confidence-building phrases. Keep explanations brief and focused on '
        'practical communication.',
  ),

  AgentType.biological: AgentConfig(
    type: AgentType.biological,
    name: 'Biological',
    subtitle: 'Fatigue & Chronic Stress',
    icon: Icons.favorite_outline,
    color: Color(0xFFE07B54),
    systemPrompt:
        'You are a wellness AI assistant. '
        'The user is suffering from physical symptoms of migration stress like '
        'fatigue or sleep disruption. Suggest actionable, non-medical daily '
        'routines, sleep hygiene tips, and stress-reduction habits.',
  ),
};
