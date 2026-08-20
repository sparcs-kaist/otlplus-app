package org.sparcs.otlplus.api

import java.util.UUID
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Test

class TokenRefreshLeaseTest {
    @Test
    fun `owner cleanup releases an active lease for the next refresher`() {
        val destroyedOwner = UUID.randomUUID().toString()
        val nextOwner = UUID.randomUUID().toString()
        val firstLease = TokenRefreshLease.acquire(destroyedOwner)
        assertNotNull(firstLease)

        TokenRefreshLease.releaseOwnedBy(destroyedOwner)

        val nextLease = TokenRefreshLease.acquire(nextOwner)
        assertNotNull(nextLease)
        TokenRefreshLease.release(requireNotNull(nextLease))
    }

    @Test
    fun `a destroyed owner cannot acquire a late lease`() {
        val destroyedOwner = UUID.randomUUID().toString()
        TokenRefreshLease.releaseOwnedBy(destroyedOwner)

        assertNull(TokenRefreshLease.acquire(destroyedOwner))
    }
}
