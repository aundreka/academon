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
  description: 'Correct answers reduce the enemy’s answer timer by 2 seconds.',
);

const ember = Ability(
  id: 'ember',
  name: 'Ember',
  type: 'attack',
  description: 'Correct answers have a 20% chance to Burn, reducing enemy Attack for 2 turns.',
);

const fireSpin = Ability(
  id: 'fireSpin',
  name: 'Fire Spin',
  type: 'control',
  description: 'Traps the enemy, forcing them to answer 3 questions in a row without healing.',
);

const blastBurn = Ability(
  id: 'blastBurn',
  name: 'Blast Burn',
  type: 'finisher',
  description: 'After 3 correct answers, the next attack deals 2x damage and skips the enemy turn.',
);

const leechSeed = Ability(
  id: 'leechSeed',
  name: 'Leech Seed',
  type: 'recovery',
  description: 'Every correct answer restores 10% of your max HP and drains it from the enemy.',
);

const sweetScent = Ability(
  id: 'sweetScent',
  name: 'Sweet Scent',
  type: 'support',
  description: 'Simplifies the current question by removing two incorrect multiple-choice options.',
);

const solarBeam = Ability(
  id: 'solarBeam',
  name: 'Solar Beam',
  type: 'special',
  description: 'After 4 turns, the next question is automatically answered correctly with 2x damage.',
);

const withdraw = Ability(
  id: 'withdraw',
  name: 'Withdraw',
  type: 'defense',
  description: 'Reduces damage taken from the next incorrect answer by 50%.',
);

const aquaRing = Ability(
  id: 'aquaRing',
  name: 'Aqua Ring',
  type: 'support',
  description: 'Extends the answer timer by 5 seconds for every question.',
);

const hydroCannon = Ability(
  id: 'hydroCannon',
  name: 'Hydro Cannon',
  type: 'utility',
  description: 'Once per match, resets the timer and provides a "Free Hint" that highlights the correct answer.',
);

const staticAbility = Ability(
  id: 'static',
  name: 'Static',
  type: 'disrupt',
  description: '30% chance to "Paralyze" the enemy on a correct answer, freezing their timer for 3 seconds.',
);

const quickAttack = Ability(
  id: 'quickAttack',
  name: 'Quick Attack',
  type: 'speed',
  description: 'If you answer within the first 5 seconds, your attack ignores the enemy’s Defense.',
);

const thunderbolt = Ability(
  id: 'thunderbolt',
  name: 'Thunderbolt',
  type: 'attack',
  description: 'Every 3rd correct answer forces the enemy to answer a "Flash Round" (reduced time) question.',
);

