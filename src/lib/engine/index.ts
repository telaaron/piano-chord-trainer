export { NOTES_SHARPS, NOTES_FLATS, ENHARMONIC_MAP, getNoteArray, getNotePool, noteToSemitone, getNoteName, convertNoteName, convertChordNotation } from './notes';
export type { NoteName, AccidentalPreference, NotationSystem } from './notes';

export { CHORDS_BY_DIFFICULTY, CHORD_INTERVALS, CHORD_NOTATIONS, VOICING_LABELS } from './chords';
export type { Difficulty, NotationStyle, VoicingType, DisplayMode, ChordType } from './chords';

export { getChordNotes, getVoicingNotes, formatVoicing, displayToQuality, getValidPCSets } from './voicings';
export type { ChordWithNotes } from './voicings';

export { WHITE_KEY_COUNT, CHROMATIC_COUNT, BLACK_KEYS, WHITE_KEY_CHROMATIC, OCTAVE_CONFIGS, generateBlackKeys, whiteKeyChromaticIndex, getActiveKeyIndices, getKeyboardLayout, isRootIndex, computeSessionOctaves } from './keyboard';
export type { OctaveCount, KeyboardLayout } from './keyboard';

export { PROGRESSION_LABELS, PROGRESSION_DESCRIPTIONS, generateProgression } from './progressions';
export type { ProgressionMode, GeneratedProgression } from './progressions';

export { PRACTICE_PLANS, suggestPlan } from './plans';
export type { PracticePlan } from './plans';

export { parseChordSymbol, parseProgression, formatProgression, PROGRESSION_PRESETS, loadCustomProgressions, saveCustomProgression, deleteCustomProgression, evaluateSession } from './custom-progressions';
export type { CustomChord, CustomProgression, ProgressionPreset, LoopEvaluation, ChordEval, SessionEvaluation } from './custom-progressions';

export { analyzeVoiceLeading, formatVoiceLeading, computeVoiceLeadVoicing, getAllRotations, scorePlayerMovement, validateFindInversion, validateFreeVoicing } from './voice-leading';
export type { VoiceLeadingInfo, VoiceMovement, VoiceLeadingMode, VLValidationResult } from './voice-leading';

export { analyzePerformance, getWeightedChordPool, pickWeightedChord, getPerformanceSummary } from './adaptive';
export type { ChordPerformance, WeightedChord } from './adaptive';

export { calculateLevel, xpForLevel, getLevelInfo, getStreakMultiplier, calculateSessionXP, sumXP, generateGoals, updateChordSchedule, timingToQuality, processSessionForSchedule, getQuickStartSuggestion, checkGoalProgress, createDefaultProfile, migrateToHabitProfile } from './habits';
export type { GoalType, TimeOfDay, SmartGoal, ChordReview, HabitProfile, XPEvent, LevelInfo, CelebrationEvent, QuickStartSuggestion } from './habits';
