import '../models/ability.dart';

const pressure = Ability(
  id: 'pressure',
  name: 'Pressure',
  type: 'attack',
  description: 'The boss stares you down. Your answer timer is permanently reduced by 3 seconds.',
);

const confuse = Ability(
  id: 'confuse',
  name: 'Confuse',
  type: 'attack',
  description: 'Scrambles the letters of the possible answers for the current question.',
);

const earthquake = Ability(
  id: 'earthquake',
  name: 'Earthquake',
  type: 'attack',
  description: 'Deals massive damage and disables your active Pokemon\'s first ability for 2 turns.',
);

const recovery = Ability(
  id: 'boss_recovery',
  name: 'Ancient Wisdom',
  type: 'support',
  description: 'The boss heals 15% of its HP if the player misses a question.',
);

const frostBite = Ability(
  id: 'frost_bite',
  name: 'Frost Bite',
  type: 'attack',
  description: 'Freezes your abilities for 3 turns if you take more than 5 seconds to answer.',
);

const stormSurge = Ability(
  id: 'storm_surge',
  name: 'Storm Surge',
  type: 'attack',
  description: 'Every 2nd correct answer by the boss hides the question text for 1.5 seconds.',
);

const photosynthesis = Ability(
  id: 'photosynthesis',
  name: 'Photosynthesis',
  type: 'support',
  description: 'The boss gains a shield equal to 10% of its Max HP every time you use a hint.',
);