package com.eclinic.features.nurse.triage

import app.cash.turbine.test
import com.eclinic.core.common.model.*
import com.eclinic.features.nurse.domain.repository.NurseRepository
import io.mockk.mockk
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Before
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class TriageViewModelTest {

    private val repository: NurseRepository = mockk()
    private lateinit var viewModel: TriageViewModel
    private val testDispatcher = StandardTestDispatcher()

    @Before
    fun setup() {
        Dispatchers.setMain(testDispatcher)
        viewModel = TriageViewModel(repository)
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    @Test
    fun `when high priority discriminator is selected, triage category should be RED`() = runTest {
        viewModel.state.test {
            // Initial state
            assertEquals(0, awaitItem().tewsScore)

            // Act: Toggle a RED flag discriminator (Shock)
            viewModel.onIntent(TriageIntent.ToggleDiscriminator(Discriminator.SHOCK))
            assertEquals(setOf(Discriminator.SHOCK), awaitItem().selectedDiscriminators)

            // Act: Calculate result
            viewModel.onIntent(TriageIntent.CalculateResult)
            val resultState = awaitItem()
            
            // Assert
            assertEquals(TriageCategory.RED, resultState.result?.triageCategory)
            assertEquals("Immediate medical attention required.", resultState.result?.recommendedAction)
        }
    }

    @Test
    fun `when TEWS score is 5, triage category should be ORANGE`() = runTest {
        viewModel.state.test {
            awaitItem() // Initial

            // Act: Update TEWS to 5
            viewModel.onIntent(TriageIntent.UpdateTews(5))
            assertEquals(5, awaitItem().tewsScore)

            // Act: Calculate result
            viewModel.onIntent(TriageIntent.CalculateResult)
            val resultState = awaitItem()

            // Assert
            assertEquals(TriageCategory.ORANGE, resultState.result?.triageCategory)
            assertEquals("Very urgent. Review within 10 minutes.", resultState.result?.recommendedAction)
        }
    }

    @Test
    fun `when TEWS score is 2 and no red flags, triage category should be GREEN`() = runTest {
        viewModel.state.test {
            awaitItem() // Initial

            // Act: Update TEWS to 2
            viewModel.onIntent(TriageIntent.UpdateTews(2))
            assertEquals(2, awaitItem().tewsScore)

            // Act: Calculate result
            viewModel.onIntent(TriageIntent.CalculateResult)
            val resultState = awaitItem()

            // Assert
            assertEquals(TriageCategory.GREEN, resultState.result?.triageCategory)
        }
    }
}
