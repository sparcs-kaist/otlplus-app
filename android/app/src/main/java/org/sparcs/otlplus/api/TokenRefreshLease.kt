package org.sparcs.otlplus.api

import java.util.UUID
import java.util.concurrent.Semaphore
import java.util.concurrent.TimeUnit

internal object TokenRefreshLease {
    private const val ACQUIRE_TIMEOUT_SECONDS = 15L
    private val semaphore = Semaphore(1, true)
    private val stateLock = Any()
    private val cancelledOwners = mutableSetOf<String>()
    private var activeLeaseId: String? = null
    private var activeOwnerId: String? = null

    fun acquire(ownerId: String = UUID.randomUUID().toString()): String? {
        synchronized(stateLock) {
            if (ownerId in cancelledOwners) return null
        }

        val acquired = try {
            semaphore.tryAcquire(ACQUIRE_TIMEOUT_SECONDS, TimeUnit.SECONDS)
        } catch (_: InterruptedException) {
            Thread.currentThread().interrupt()
            false
        }
        if (!acquired) return null

        return synchronized(stateLock) {
            if (ownerId in cancelledOwners) {
                semaphore.release()
                null
            } else {
                UUID.randomUUID().toString().also { leaseId ->
                    activeLeaseId = leaseId
                    activeOwnerId = ownerId
                }
            }
        }
    }

    fun release(leaseId: String) {
        val shouldRelease = synchronized(stateLock) {
            if (activeLeaseId != leaseId) {
                false
            } else {
                activeLeaseId = null
                activeOwnerId = null
                true
            }
        }
        if (shouldRelease) semaphore.release()
    }

    fun releaseOwnedBy(ownerId: String) {
        val shouldRelease = synchronized(stateLock) {
            cancelledOwners += ownerId
            if (activeOwnerId != ownerId) {
                false
            } else {
                activeLeaseId = null
                activeOwnerId = null
                true
            }
        }
        if (shouldRelease) semaphore.release()
    }
}
