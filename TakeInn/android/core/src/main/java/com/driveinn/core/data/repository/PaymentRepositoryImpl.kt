package com.driveinn.core.data.repository

import com.driveinn.core.data.model.PaymentInitiationRequest
import com.driveinn.core.data.model.PaymentInitiationResponse
import com.driveinn.core.data.remote.PaymentService
import javax.inject.Inject

class PaymentRepositoryImpl @Inject constructor(
    private val paymentService: PaymentService
) : PaymentRepository {
    override suspend fun initiatePayment(request: PaymentInitiationRequest): PaymentInitiationResponse {
        return paymentService.initiatePayment(request)
    }
}
