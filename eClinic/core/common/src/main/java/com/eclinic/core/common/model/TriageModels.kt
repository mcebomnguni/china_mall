package com.eclinic.core.common.model

import kotlinx.serialization.Serializable

@Serializable
data class SatsScore(
    val tewsScore: Int, // Triage Early Warning Score
    val mobility: Mobility, // Walking, On own, Carried
    val hasTrauma: Boolean,
    val ageGroup: AgeGroup,
    val clinicalDiscriminators: Set<Discriminator> = emptySet()
)

@Serializable
data class SatsResult(
    val finalScore: Int,
    val triageCategory: TriageCategory, // RED, ORANGE, YELLOW, GREEN
    val recommendedAction: String
)

@Serializable
enum class Mobility {
    WALKING, ON_OWN_BUT_NOT_WALKING, CARRIED_ASSISTED
}

@Serializable
enum class AgeGroup {
    NEONATE, INFANT, CHILD, ADULT
}

@Serializable
enum class Discriminator {
    // Life-threatening conditions that immediately upgrade triage
    AIRWAY_OBSTRUCTION,
    SEVERE_RESPIRATORY_DISTRESS,
    CENTRAL_CYANOSIS,
    SHOCK,
    UNRESPONSIVE_GCS_LT_9,
    SEIZURE_ACTIVITY,
    SEVERE_DEHYDRATION,
    SEVERE_PAIN,
    SEVERE_BLEEDING,
    MAJOR_TRAUMA
    // ... and others as defined by SATS
}
