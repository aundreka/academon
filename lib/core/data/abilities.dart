import '../models/ability.dart';

const shield = Ability(
  id: 'shield',
  name: 'Shield',
  type: 'defense',
  description: 'Blocks one wrong-answer penalty.',
);

const timeRewind = Ability(
  id: 'rewind',
  name: 'Time Rewind',
  type: 'support',
  description: 'Gives extra time to answer.',
);

const teleport = Ability(
  id: 'teleport',
  name: 'Teleport',
  type: 'defense',
  description: '50% chance to dodge damage and reset the question.',
);

const kinesis = Ability(
  id: 'kinesis',
  name: 'Kinesis',
  type: 'attack',
  description: 'Forces the enemy to answer a difficult Identification question.',
);

const ironFist = Ability(
  id: 'ironFist',
  name: 'Iron Fist',
  type: 'utility',
  description: 'Correct answers reduce the enemy timer by 2 seconds.',
);

const ember = Ability(
  id: 'ember',
  name: 'Ember',
  type: 'attack',
  description: 'Correct answers have a 20% chance to Burn and reduce enemy Attack.',
);

const fireSpin = Ability(
  id: 'fireSpin',
  name: 'Fire Spin',
  type: 'control',
  description: 'Traps the enemy into answering multiple questions in a row.',
);

const blastBurn = Ability(
  id: 'blastBurn',
  name: 'Blast Burn',
  type: 'finisher',
  description: 'After 3 correct answers, the next attack deals 2x damage.',
);

const leechSeed = Ability(
  id: 'leechSeed',
  name: 'Leech Seed',
  type: 'recovery',
  description: 'Every correct answer restores HP and drains the enemy.',
);

const sweetScent = Ability(
  id: 'sweetScent',
  name: 'Sweet Scent',
  type: 'support',
  description: 'Removes two wrong multiple-choice options from a question.',
);

const solarBeam = Ability(
  id: 'solarBeam',
  name: 'Solar Beam',
  type: 'special',
  description: 'Charges up and auto-answers the next question for 2x damage.',
);

const withdraw = Ability(
  id: 'withdraw',
  name: 'Withdraw',
  type: 'defense',
  description: 'Reduces damage from the next incorrect answer by 50%.',
);

const aquaRing = Ability(
  id: 'aquaRing',
  name: 'Aqua Ring',
  type: 'support',
  description: 'Extends the answer timer by 5 seconds.',
);

const hydroCannon = Ability(
  id: 'hydroCannon',
  name: 'Hydro Cannon',
  type: 'utility',
  description: 'Resets the timer and highlights the correct answer once per match.',
);

const staticAbility = Ability(
  id: 'static',
  name: 'Static',
  type: 'disrupt',
  description: 'Correct answers can Paralyze the enemy and freeze their timer.',
);

const quickAttack = Ability(
  id: 'quickAttack',
  name: 'Quick Attack',
  type: 'speed',
  description: 'Fast answers ignore the enemy defense.',
);

const thunderbolt = Ability(
  id: 'thunderbolt',
  name: 'Thunderbolt',
  type: 'attack',
  description: 'Every third correct answer triggers a flash-round challenge.',
);

const shadowSneak = Ability(
  id: 'shadowSneak',
  name: 'Shadow Sneak',
  type: 'speed',
  description: 'A quick answer lets you strike first and shave 1 second off the enemy timer.',
);

const curseMist = Ability(
  id: 'curseMist',
  name: 'Curse Mist',
  type: 'control',
  description: 'Wrong answers from the enemy reduce their next damage output.',
);

const phantomRaid = Ability(
  id: 'phantomRaid',
  name: 'Phantom Raid',
  type: 'finisher',
  description: 'After a streak of correct answers, deal heavy damage and ignore shields.',
);

const bubbleBurst = Ability(
  id: 'bubbleBurst',
  name: 'Bubble Burst',
  type: 'support',
  description: 'Adds a short slow effect to the enemy timer after each correct answer.',
);

const tidalFocus = Ability(
  id: 'tidalFocus',
  name: 'Tidal Focus',
  type: 'special',
  description: 'Your next question gains extra time and bonus damage on success.',
);

const moonCharm = Ability(
  id: 'moonCharm',
  name: 'Moon Charm',
  type: 'support',
  description: 'Gives a small shield and a hint after two correct answers in a row.',
);

const poisonPowder = Ability(
  id: 'poisonPowder',
  name: 'Poison Powder',
  type: 'disrupt',
  description: 'Inflicts lingering chip damage whenever the enemy answers incorrectly.',
);

const venomBloom = Ability(
  id: 'venomBloom',
  name: 'Venom Bloom',
  type: 'special',
  description: 'Combines poison and healing to pressure the enemy over several turns.',
);
const splash = Ability(
  id: 'splash',
  name: 'Splash',
  type: 'useless',
  description: 'Does nothing... but unlocks hidden potential.',
);

const sandAttack = Ability(
  id: 'sandAttack',
  name: 'Sand Attack',
  type: 'control',
  description: 'Reduces enemy accuracy (longer answer time pressure).',
);

const hurricaneStrike = Ability(
  id: 'hurricaneStrike',
  name: 'Hurricane Strike',
  type: 'finisher',
  description: 'Strong wind-based attack that boosts final damage.',
);

const adaptation = Ability(
  id: 'adaptation',
  name: 'Adaptation',
  type: 'support',
  description: 'Eevee adapts: boosts random stat each round.',
);

const psychicBurst = Ability(
  id: 'psychicBurst',
  name: 'Psychic Burst',
  type: 'attack',
  description: 'High damage psychic overload after streak.',
);

const auraGuard = Ability(
  id: 'auraGuard',
  name: 'Aura Guard',
  type: 'defense',
  description: 'Reduces incoming damage after wrong answers.',
);