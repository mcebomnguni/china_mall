package com.eclinic.features.nurse.triage

import com.eclinic.core.common.model.Discriminator
import com.eclinic.core.common.model.Mobility
import com.eclinic.core.common.model.SatsResult
import com.eclinic.core.common.model.TriageCategory

data class TriageState(
    val isLoading: Boolean = false,
    val patientId: String = "",
    val mobility: Mobility = Mobility.WALKING,
    val hasTrauma: Boolean = false,
    val tewsScore: Int = 0,
    val selectedDiscriminators: Set<Discriminator> = emptySet(),
    val result: SatsResult? = null,
    val error: String? = null,
    val isSaved: Boolean = false
)

sealed interface TriageIntent {
    data class LoadPatient(val patientId: String) : TriageIntent
    data class UpdateMobility(val mobility: Mobility) : TriageIntent
    data class UpdateTrauma(val hasTrauma: Boolean) : TriageIntent
    data class UpdateTews(val score: Int) : TriageIntent
    data class ToggleDiscriminator(val discriminator: Discriminator) : TriageIntent
    object CalculateResult : TriageIntent
    object SaveTriage : TriageIntent
}
