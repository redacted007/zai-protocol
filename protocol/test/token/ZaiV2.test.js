const { accounts, contract } = require('@openzeppelin/test-environment')

const {
  BN,
  expectRevert,
  time,
  expectEvent,
  constants,
} = require('@openzeppelin/test-helpers')
const { expect } = require('chai')

const MockOldZai = contract.fromArtifact('MockOldZai')
const ZaiV2 = contract.fromArtifact('ZaiV2')

const MAX_OLD_ZAI = new BN('395407172763503943977588203')
const SWAP_RATE = new BN('100')

describe('ZaiV2', function () {
  const [ownerAddress, userAddress, poolAddress] = accounts

  beforeEach(async function () {
    this.oldZai = await MockOldZai.new()
    this.zai2 = await ZaiV2.new(this.oldZai.address, {
      from: ownerAddress,
      gas: 8000000,
    })
  })

  describe('burnAndSwap', function () {
    describe('small time', async function () {
      beforeEach(async function () {
        await this.oldZai.mint(userAddress, 100)
        expect(await this.oldZai.balanceOf(userAddress)).to.be.bignumber.equal(
          new BN(100),
        )

        expect(await this.oldZai.totalSupply()).to.be.bignumber.equal(
          new BN(100),
        )
        expect(await this.zai2.totalSupply()).to.be.bignumber.equal(new BN(0))
      })

      describe('without approval ', function () {
        it('fails miserably', async function () {
          await expectRevert(
            this.zai2.burnAndSwap(userAddress),
            'gotta burn if you wanna earn...',
          )
        })
      })

      describe('with approval ', function () {
        beforeEach(async function () {
          await this.oldZai.approve(this.zai2.address, 100, {
            from: userAddress,
          })
        })

        it('works', async function () {
          const tx = await this.zai2.burnAndSwap(userAddress, {
            from: userAddress,
          })

          // Check events
          const event = expectEvent.inLogs(tx.logs, 'BurnAndSwap')
          expect(event.args.from).to.be.equal(userAddress)
          expect(event.args.burnAmount).to.be.bignumber.equal(new BN(100))
          expect(event.args.mintAmount).to.be.bignumber.equal(new BN(1))

          const totalSupply = await this.zai2.totalSupply()
          expect(totalSupply).to.be.bignumber.equal(new BN(1))

          // Make sure the ZAI is burned
          const oldZaiSupply = await this.oldZai.totalSupply()
          expect(oldZaiSupply).to.be.bignumber.equal(new BN(0))
        })
      })

      describe('too much approval', function () {
        beforeEach(async function () {
          await this.oldZai.approve(this.zai2.address, 101, {
            from: userAddress,
          })
        })

        it('fails miserably', async function () {
          await expectRevert(
            this.zai2.burnAndSwap(userAddress),
            ' ERC20: transfer amount exceeds balance.',
          )
        })
      })
    })
  })

  describe('whale game', async function () {
    const AMOUNT = MAX_OLD_ZAI.add(new BN(1))

    beforeEach(async function () {
      await this.oldZai.mint(userAddress, AMOUNT)
      expect(await this.oldZai.balanceOf(userAddress)).to.be.bignumber.equal(
        new BN(AMOUNT),
      )

      expect(await this.oldZai.totalSupply()).to.be.bignumber.equal(
        new BN(AMOUNT),
      )
      expect(await this.zai2.totalSupply()).to.be.bignumber.equal(new BN(0))
    })

    describe('possible whale', async function () {
      beforeEach(async function () {
        await this.oldZai.approve(this.zai2.address, MAX_OLD_ZAI, {
          from: userAddress,
        })
      })

      it('works for that chad', async function () {
        const tx = await this.zai2.burnAndSwap(userAddress, {
          from: userAddress,
        })
        // Check events
        const event = expectEvent.inLogs(tx.logs, 'BurnAndSwap')
        expect(event.args.from).to.be.equal(userAddress)
        expect(event.args.burnAmount).to.be.bignumber.equal(new BN(MAX_OLD_ZAI))
        expect(event.args.mintAmount).to.be.bignumber.equal(
          new BN(MAX_OLD_ZAI.div(SWAP_RATE)),
        )

        expect(await this.zai2.totalSupply()).to.be.bignumber.equal(
          new BN(MAX_OLD_ZAI.div(SWAP_RATE)),
        )

        // Make sure the ZAI is burned
        expect(await this.oldZai.totalSupply()).to.be.bignumber.equal(new BN(1))
      })
    })

    describe('impossible whale', async function () {
      beforeEach(async function () {
        await this.oldZai.approve(this.zai2.address, AMOUNT, {
          from: userAddress,
        })
      })

      it('bails', async function () {
        await expectRevert(
          this.zai2.burnAndSwap(userAddress, {
            from: userAddress,
          }),
          'where did all that ZAI come from...',
        )

        expect(await this.oldZai.balanceOf(userAddress)).to.be.bignumber.equal(
          AMOUNT,
        )
        expect(await this.zai2.balanceOf(userAddress)).to.be.bignumber.equal(
          '0',
        )

        expect(await this.oldZai.totalSupply()).to.be.bignumber.equal(AMOUNT)
        expect(await this.zai2.totalSupply()).to.be.bignumber.equal(new BN(0))
      })
    })

    describe('multi whale', async function () {
      it('works', async function () {
        // 1 less than limit
        await this.oldZai.approve(
          this.zai2.address,
          AMOUNT.sub(new BN('200')),
          {
            from: userAddress,
          },
        )
        await this.zai2.burnAndSwap(userAddress, {
          from: userAddress,
        })
        // At the limit
        await this.oldZai.approve(this.zai2.address, new BN('100'), {
          from: userAddress,
        })
        await this.zai2.burnAndSwap(userAddress, {
          from: userAddress,
        })

        // Over the limit
        await this.oldZai.approve(this.zai2.address, new BN('100'), {
          from: userAddress,
        })
        await expectRevert(
          this.zai2.burnAndSwap(userAddress, {
            from: userAddress,
          }),
          'where did all that ZAI come from...',
        )
      })
    })
  })
})
