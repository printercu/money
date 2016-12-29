# encoding: utf-8

describe Money do
  describe "-@" do
    it "changes the sign of a number" do
      expect((- Money.new(0))).to  eq Money.new(0)
      expect((- Money.new(1))).to  eq Money.new(-1)
      expect((- Money.new(-1))).to eq Money.new(1)
    end

    it "preserves the class in the result when using a subclass of Money" do
      special_money_class = Class.new(Money)
      expect(- special_money_class.new(10_00)).to be_a special_money_class
    end
  end

  describe "#==" do
    it "returns true if both the amounts and currencies are equal" do
      expect(Money.new(1_00, "USD")).to     eq Money.new(1_00, "USD")
      expect(Money.new(1_00, "USD")).not_to eq Money.new(1_00, "EUR")
      expect(Money.new(1_00, "USD")).not_to eq Money.new(2_00, "USD")
      expect(Money.new(1_00, "USD")).not_to eq Money.new(99_00, "EUR")
    end

    it "returns true if both amounts are zero, even if currency differs" do
      allow_any_instance_of(Money).to receive(:exchange_to) { Money.usd(0) }
      expect(Money.new(0, "USD")).to eq Money.new(0, "USD")
      expect(Money.new(0, "USD")).to eq Money.new(0, "EUR")
      expect(Money.new(0, "USD")).to eq Money.new(0, "AUD")
      expect(Money.new(0, "USD")).to eq Money.new(0, "JPY")
    end

    it "returns false if used to compare with an object that doesn't inherit from Money" do
      expect(Money.new(1_00, "USD")).not_to eq Object.new
      expect(Money.new(1_00, "USD")).not_to eq Class
      expect(Money.new(1_00, "USD")).not_to eq Kernel
      expect(Money.new(1_00, "USD")).not_to eq(/foo/)
      expect(Money.new(1_00, "USD")).not_to eq nil
    end

    it "can be used to compare with an object that inherits from Money" do
      klass = Class.new(Money)

      expect(Money.new(1_00, "USD")).to     eq klass.new(1_00, "USD")
      expect(Money.new(2_50, "USD")).to     eq klass.new(2_50, "USD")
      expect(Money.new(2_50, "USD")).not_to eq klass.new(3_00, "USD")
      expect(Money.new(1_00, "GBP")).not_to eq klass.new(1_00, "USD")
    end

    it 'returns false when other object is not money' do
      expect(Money.usd(0) == 0).to eq false
      expect(Money.usd(0) == 0.0).to eq false
      expect(Money.usd(1) == 1).to eq false
      expect(Money.usd(1) == 100).to eq false
    end
  end

  describe "#eql?" do
    it "returns true if and only if their amount and currency are equal" do
      expect(Money.new(1_00, "USD").eql?(Money.new(1_00, "USD"))).to  be true
      expect(Money.new(1_00, "USD").eql?(Money.new(1_00, "EUR"))).to  be false
      expect(Money.new(1_00, "USD").eql?(Money.new(2_00, "USD"))).to  be false
      expect(Money.new(1_00, "USD").eql?(Money.new(99_00, "EUR"))).to be false
    end

    it "returns false if used to compare with an object that doesn't inherit from Money" do
      expect(Money.new(1_00, "USD").eql?(Object.new)).to  be false
      expect(Money.new(1_00, "USD").eql?(Class)).to       be false
      expect(Money.new(1_00, "USD").eql?(Kernel)).to      be false
      expect(Money.new(1_00, "USD").eql?(/foo/)).to       be false
      expect(Money.new(1_00, "USD").eql?(nil)).to         be false
    end

    it "can be used to compare with an object that inherits from Money" do
      klass = Class.new(Money)

      expect(Money.new(1_00, "USD").eql?(klass.new(1_00, "USD"))).to be true
      expect(Money.new(2_50, "USD").eql?(klass.new(2_50, "USD"))).to be true
      expect(Money.new(2_50, "USD").eql?(klass.new(3_00, "USD"))).to be false
      expect(Money.new(1_00, "GBP").eql?(klass.new(1_00, "USD"))).to be false
    end
  end

  describe "#<=>" do
    it "compares the two object amounts (same currency)" do
      expect((Money.new(1_00, "USD") <=> Money.new(1_00, "USD"))).to eq 0
      expect((Money.new(1_00, "USD") <=> Money.new(99, "USD"))).to be > 0
      expect((Money.new(1_00, "USD") <=> Money.new(2_00, "USD"))).to be < 0
    end

    it "converts other object amount to current currency, then compares the two object amounts (different currency)" do
      target = Money.new(200_00, "EUR")
      expect(target).to receive(:exchange_to).with(Money::Currency.new("USD")).and_return(Money.new(300_00, "USD"))
      expect(Money.new(100_00, "USD") <=> target).to be < 0

      target = Money.new(200_00, "EUR")
      expect(target).to receive(:exchange_to).with(Money::Currency.new("USD")).and_return(Money.new(100_00, "USD"))
      expect(Money.new(100_00, "USD") <=> target).to eq 0

      target = Money.new(200_00, "EUR")
      expect(target).to receive(:exchange_to).with(Money::Currency.new("USD")).and_return(Money.new(99_00, "USD"))
      expect(Money.new(100_00, "USD") <=> target).to be > 0
    end

    it "returns nil if currency conversion fails, and therefore cannot be compared" do
      target = Money.new(200_00, "EUR")
      expect(target).to receive(:exchange_to).with(Money::Currency.new("USD")).and_raise(Money::Bank::UnknownRate)
      expect(Money.new(100_00, "USD") <=> target).to be_nil
    end

    it "can be used to compare with an object that inherits from Money" do
      klass = Class.new(Money)

      expect(Money.new(1_00) <=> klass.new(1_00)).to eq 0
      expect(Money.new(1_00) <=> klass.new(99)).to be > 0
      expect(Money.new(1_00) <=> klass.new(2_00)).to be < 0
    end

    it "returns nill when comparing with an object that doesn't inherit from Money" do
      expect(Money.usd(1) <=> 1).to be_nil
      expect(Money.usd(1) <=> Object.new).to be_nil
      expect(Money.usd(1) <=> Class).to be_nil
      expect(Money.usd(1) <=> Kernel).to be_nil
      expect(Money.usd(1) <=> /foo/).to be_nil
      expect(Money.usd(1) <=> 0).to eq nil
    end
  end

  describe "#positive?" do
    it "returns true if the amount is greater than 0" do
      expect(Money.new(1)).to be_positive
    end

    it "returns false if the amount is 0" do
      expect(Money.new(0)).not_to be_positive
    end

    it "returns false if the amount is negative" do
      expect(Money.new(-1)).not_to be_positive
    end
  end

  describe "#negative?" do
    it "returns true if the amount is less than 0" do
      expect(Money.new(-1)).to be_negative
    end

    it "returns false if the amount is 0" do
      expect(Money.new(0)).not_to be_negative
    end

    it "returns false if the amount is greater than 0" do
      expect(Money.new(1)).not_to be_negative
    end
  end

  describe "#+" do
    it "adds other amount to current amount (same currency)" do
      expect(Money.new(10_00, "USD") + Money.new(90, "USD")).to eq Money.new(10_90, "USD")
    end

    it "converts other object amount to current currency and adds other amount to current amount (different currency)" do
      other = Money.new(90, "EUR")
      expect(other).to receive(:exchange_to).with(Money::Currency.new("USD")).and_return(Money.new(9_00, "USD"))
      expect(Money.new(10_00, "USD") + other).to eq Money.new(19_00, "USD")
    end

    it "preserves the class in the result when using a subclass of Money" do
      special_money_class = Class.new(Money)
      expect(special_money_class.new(10_00, "USD") + Money.new(90, "USD")).to be_a special_money_class
    end
  end

  describe "#-" do
    it "subtracts other amount from current amount (same currency)" do
      expect(Money.new(10_00, "USD") - Money.new(90, "USD")).to eq Money.new(9_10, "USD")
    end

    it "converts other object amount to current currency and subtracts other amount from current amount (different currency)" do
      other = Money.new(90, "EUR")
      expect(other).to receive(:exchange_to).with(Money::Currency.new("USD")).and_return(Money.new(9_00, "USD"))
      expect(Money.new(10_00, "USD") - other).to eq Money.new(1_00, "USD")
    end

    it "preserves the class in the result when using a subclass of Money" do
      special_money_class = Class.new(Money)
      expect(special_money_class.new(10_00, "USD") - Money.new(90, "USD")).to be_a special_money_class
    end
  end

  describe "#*" do
    it "multiplies Money by Integer and returns Money" do
      [
        [Money.new( 10, :USD),  4, Money.new( 40, :USD)],
        [Money.new( 10, :USD), -4, Money.new(-40, :USD)],
        [Money.new(-10, :USD),  4, Money.new(-40, :USD)],
        [Money.new(-10, :USD), -4, Money.new( 40, :USD)],
      ].each do |(a, b, result)|
        expect(a * b).to eq result
      end
    end

    it "does not multiply Money by Money (same currency)" do
      expect { Money.new(10, :USD) * Money.new(4, :USD) }.to raise_error(TypeError)
    end

    it "does not multiply Money by Money (different currency)" do
      expect { Money.new(10, :USD) * Money.new(4, :EUR) }.to raise_error(TypeError)
    end

    it "does not multiply Money by an object which is NOT a number" do
      expect { Money.new(10, :USD) *  'abc' }.to raise_error(TypeError)
    end

    it "preserves the class in the result when using a subclass of Money" do
      special_money_class = Class.new(Money)
      expect(special_money_class.new(10_00, "USD") * 2).to be_a special_money_class
    end
  end

  %w(+ -).each do |op|
    describe "##{op}" do
      it 'raises error for non-money' do
        money = Money.usd(1)
        expect { money.send(op, 0) }.to raise_error TypeError
        expect { money.send(op, 0.0) }.to raise_error TypeError
        expect { money.send(op, 1) }.to raise_error TypeError
        expect { money.send(op, 1.0) }.to raise_error TypeError
      end
    end
  end

  describe "#/" do
    it "divides Money by Integer and returns Money" do
      [
        [Money.usd( 0.13),  4, Money.usd( 0.03)],
        [Money.usd( 0.13), -4, Money.usd(-0.03)],
        [Money.usd(-0.13),  4, Money.usd(-0.03)],
        [Money.usd(-0.13), -4, Money.usd( 0.03)],
      ].each do |(a, b, result)|
        expect(a / b).to eq result
      end
    end

    it "preserves the class in the result when using a subclass of Money" do
      special_money_class = Class.new(Money)
      expect(special_money_class.new(10_00, "USD") / 2).to be_a special_money_class
    end

    context 'rounding preference' do
      context 'ceiling rounding' do
        with_rounding_mode BigDecimal::ROUND_CEILING
        it "obeys the rounding preference" do
          expect(Money.usd(0.1) / 3).to eq Money.usd(0.04)
        end
      end

      context 'floor rounding' do
        with_rounding_mode BigDecimal::ROUND_FLOOR
        it "obeys the rounding preference" do
          expect(Money.usd(0.1) / 6).to eq Money.usd(0.01)
        end
      end

      context 'half up rounding' do
        with_rounding_mode BigDecimal::ROUND_HALF_UP
        it "obeys the rounding preference" do
          expect(Money.usd(0.1) / 4).to eq Money.usd(0.03)
        end
      end

      context 'half down rounding' do
        with_rounding_mode BigDecimal::ROUND_HALF_DOWN
        it "obeys the rounding preference" do
          expect(Money.usd(0.1) / 4).to eq Money.usd(0.02)
        end
      end
    end

    it "divides Money by Money (same currency) and returns BigDecimal" do
      [
        [Money.new( 13, :USD), Money.new( 4, :USD),  3.25],
        [Money.new( 13, :USD), Money.new(-4, :USD), -3.25],
        [Money.new(-13, :USD), Money.new( 4, :USD), -3.25],
        [Money.new(-13, :USD), Money.new(-4, :USD),  3.25],
      ].each do |(a, b, result)|
        expect(a / b).to eq result
      end
    end

    it "divides Money by Money (different currency) and returns BigDecimal" do
      [
        [Money.new( 13, :USD), Money.new( 4, :EUR),  1.625],
        [Money.new( 13, :USD), Money.new(-4, :EUR), -1.625],
        [Money.new(-13, :USD), Money.new( 4, :EUR), -1.625],
        [Money.new(-13, :USD), Money.new(-4, :EUR),  1.625],
      ].each do |(a, b, result)|
        expect(b).to receive(:exchange_to).
          with(a.currency) { Money.new(b.to_d * 2, a.currency) }
        expect(a / b).to eq result
      end
    end

    context "with infinite_precision", :infinite_precision do
      it "uses BigDecimal division" do
        [
        [Money.new( 13, :USD),  4, Money.new( 3.25, :USD)],
        [Money.new( 13, :USD), -4, Money.new(-3.25, :USD)],
        [Money.new(-13, :USD),  4, Money.new(-3.25, :USD)],
        [Money.new(-13, :USD), -4, Money.new( 3.25, :USD)],
        ].each do |(a, b, result)|
          expect(a / b).to eq result
        end
      end
    end
  end

  describe "#div" do
    it "divides Money by Integer and returns Money" do
      [
        [Money.usd( 0.13),  4, Money.usd( 0.03)],
        [Money.usd( 0.13), -4, Money.usd(-0.03)],
        [Money.usd(-0.13),  4, Money.usd(-0.03)],
        [Money.usd(-0.13), -4, Money.usd( 0.03)],
      ].each do |(a, b, result)|
        expect(a.div(b)).to eq result
      end
    end

    it "divides Money by Money (same currency) and returns BigDecimal" do
      [
        [Money.new( 13, :USD), Money.new( 4, :USD),  3.25],
        [Money.new( 13, :USD), Money.new(-4, :USD), -3.25],
        [Money.new(-13, :USD), Money.new( 4, :USD), -3.25],
        [Money.new(-13, :USD), Money.new(-4, :USD),  3.25],
      ].each do |(a, b, result)|
        expect(a.div(b)).to eq result
      end
    end

    it "divides Money by Money (different currency) and returns BigDecimal" do
      [
        [Money.new( 13, :USD), Money.new( 4, :EUR),  1.625],
        [Money.new( 13, :USD), Money.new(-4, :EUR), -1.625],
        [Money.new(-13, :USD), Money.new( 4, :EUR), -1.625],
        [Money.new(-13, :USD), Money.new(-4, :EUR),  1.625],
      ].each do |(a, b, result)|
        expect(b).to receive(:exchange_to).
          with(a.currency) { Money.new(b.to_d * 2, :USD) }
        expect(a.div(b)).to eq result
      end
    end

    context "with infinite_precision", :infinite_precision do
      it "uses BigDecimal division" do
        [
        [Money.new( 13, :USD),  4, Money.new( 3.25, :USD)],
        [Money.new( 13, :USD), -4, Money.new(-3.25, :USD)],
        [Money.new(-13, :USD),  4, Money.new(-3.25, :USD)],
        [Money.new(-13, :USD), -4, Money.new( 3.25, :USD)],
        ].each do |(a, b, result)|
          expect(a.div(b)).to eq result
        end
      end
    end
  end

  describe "#divmod" do
    it "calculates division and modulo with Integer" do
      [
        [Money.new( 0.13, :USD),  4, [Money.new( 0.03, :USD), Money.new( 0.01, :USD)]],
        [Money.new( 0.13, :USD), -4, [Money.new(-0.04, :USD), Money.new(-0.03, :USD)]],
        [Money.new(-0.13, :USD),  4, [Money.new(-0.04, :USD), Money.new( 0.03, :USD)]],
        [Money.new(-0.13, :USD), -4, [Money.new( 0.03, :USD), Money.new(-0.01, :USD)]],
      ].each do |(a, b, result)|
        expect(a.divmod(b)).to eq result
      end
    end

    it "calculates division and modulo with Money (same currency)" do
      [
        [Money.new( 13, :USD), Money.new( 4, :USD), [ 3, Money.new( 1, :USD)]],
        [Money.new( 13, :USD), Money.new(-4, :USD), [-4, Money.new(-3, :USD)]],
        [Money.new(-13, :USD), Money.new( 4, :USD), [-4, Money.new( 3, :USD)]],
        [Money.new(-13, :USD), Money.new(-4, :USD), [ 3, Money.new(-1, :USD)]],
      ].each do |(a, b, result)|
        expect(a.divmod(b)).to eq result
      end
    end

    it "calculates division and modulo with Money (different currency)" do
      [
        [Money.new( 13, :USD), Money.new( 4, :EUR), [ 1, Money.new( 5, :USD)]],
        [Money.new( 13, :USD), Money.new(-4, :EUR), [-2, Money.new(-3, :USD)]],
        [Money.new(-13, :USD), Money.new( 4, :EUR), [-2, Money.new( 3, :USD)]],
        [Money.new(-13, :USD), Money.new(-4, :EUR), [ 1, Money.new(-5, :USD)]],
      ].each do |(a, b, result)|
        expect(b).to receive(:exchange_to).
          with(a.currency) { Money.new(b.to_d * 2, a.currency) }
        expect(a.divmod(b)).to eq result
      end
    end

    context "with infinite_precision", :infinite_precision do
      it "uses BigDecimal division" do
        [
            [Money.new( 0.13, :USD),  4, [Money.new( 0.03, :USD), Money.new( 0.01, :USD)]],
            [Money.new( 0.13, :USD), -4, [Money.new(-0.04, :USD), Money.new(-0.03, :USD)]],
            [Money.new(-0.13, :USD),  4, [Money.new(-0.04, :USD), Money.new( 0.03, :USD)]],
            [Money.new(-0.13, :USD), -4, [Money.new( 0.03, :USD), Money.new(-0.01, :USD)]],
        ].each do |(a, b, result)|
          expect(a.divmod(b)).to eq result
        end
      end
    end

    it "preserves the class in the result when dividing a subclass of Money by a fixnum" do
      special_money_class = Class.new(Money)
      expect(special_money_class.new(10_00, "USD").divmod(4).last).to be_a special_money_class
    end

    it "preserves the class in the result when using a subclass of Money by a subclass of Money" do
      special_money_class = Class.new(Money)
      expect(special_money_class.new(10_00, "USD").divmod(special_money_class.new(4_00)).last).to be_a special_money_class
    end
  end

  describe "#modulo" do
    it "calculates modulo with Integer" do
      [
        [Money.new( 13, :USD),  4, Money.new( 1, :USD)],
        [Money.new( 13, :USD), -4, Money.new(-3, :USD)],
        [Money.new(-13, :USD),  4, Money.new( 3, :USD)],
        [Money.new(-13, :USD), -4, Money.new(-1, :USD)],
      ].each do |(a, b, result)|
        expect(a.modulo(b)).to eq result
      end
    end

    it "calculates modulo with Money (same currency)" do
      [
        [Money.new( 13, :USD), Money.new( 4, :USD), Money.new( 1, :USD)],
        [Money.new( 13, :USD), Money.new(-4, :USD), Money.new(-3, :USD)],
        [Money.new(-13, :USD), Money.new( 4, :USD), Money.new( 3, :USD)],
        [Money.new(-13, :USD), Money.new(-4, :USD), Money.new(-1, :USD)],
      ].each do |(a, b, result)|
        expect(a.modulo(b)).to eq result
      end
    end

    it "calculates modulo with Money (different currency)" do
      [
        [Money.new( 13, :USD), Money.new( 4, :EUR), Money.new( 5, :USD)],
        [Money.new( 13, :USD), Money.new(-4, :EUR), Money.new(-3, :USD)],
        [Money.new(-13, :USD), Money.new( 4, :EUR), Money.new( 3, :USD)],
        [Money.new(-13, :USD), Money.new(-4, :EUR), Money.new(-5, :USD)],
      ].each do |(a, b, result)|
        expect(b).to receive(:exchange_to).
          with(a.currency) { Money.new(b.to_d * 2, a.currency) }
        expect(a.modulo(b)).to eq result
      end
    end
  end

  describe "#%" do
    it "calculates modulo with Integer" do
      [
        [Money.new( 13, :USD),  4, Money.new( 1, :USD)],
        [Money.new( 13, :USD), -4, Money.new(-3, :USD)],
        [Money.new(-13, :USD),  4, Money.new( 3, :USD)],
        [Money.new(-13, :USD), -4, Money.new(-1, :USD)],
      ].each do |(a, b, result)|
        expect(a % b).to eq result
      end
    end

    it "calculates modulo with Money (same currency)" do
      [
        [Money.new( 13, :USD), Money.new( 4, :USD), Money.new( 1, :USD)],
        [Money.new( 13, :USD), Money.new(-4, :USD), Money.new(-3, :USD)],
        [Money.new(-13, :USD), Money.new( 4, :USD), Money.new( 3, :USD)],
        [Money.new(-13, :USD), Money.new(-4, :USD), Money.new(-1, :USD)],
      ].each do |(a, b, result)|
        expect(a % b).to eq result
      end
    end

    it "calculates modulo with Money (different currency)" do
      [
        [Money.new( 13, :USD), Money.new( 4, :EUR), Money.new( 5, :USD)],
        [Money.new( 13, :USD), Money.new(-4, :EUR), Money.new(-3, :USD)],
        [Money.new(-13, :USD), Money.new( 4, :EUR), Money.new( 3, :USD)],
        [Money.new(-13, :USD), Money.new(-4, :EUR), Money.new(-5, :USD)],
      ].each do |(a, b, result)|
        expect(b).to receive(:exchange_to).
          with(a.currency) { Money.new(b.to_d * 2, a.currency) }
        expect(a % b).to eq result
      end
    end
  end

  describe "#remainder" do
    it "calculates remainder with Integer" do
      [
        [Money.new( 13, :USD),  4, Money.new( 1, :USD)],
        [Money.new( 13, :USD), -4, Money.new( 1, :USD)],
        [Money.new(-13, :USD),  4, Money.new(-1, :USD)],
        [Money.new(-13, :USD), -4, Money.new(-1, :USD)],
      ].each do |(a, b, result)|
        expect(a.remainder(b)).to eq result
      end
    end
  end

  describe "#abs" do
    it "returns the absolute value as a new Money object" do
      n = Money.new(-1, :USD)
      expect(n.abs).to eq Money.new( 1, :USD)
      expect(n).to     eq Money.new(-1, :USD)
    end

    it "preserves the class in the result when using a subclass of Money" do
      special_money_class = Class.new(Money)
      expect(special_money_class.new(-1).abs).to be_a special_money_class
    end
  end

  describe "#zero?" do
    it "returns whether the amount is 0" do
      expect(Money.new(0, "USD")).to be_zero
      expect(Money.new(0, "EUR")).to be_zero
      expect(Money.new(1, "USD")).not_to be_zero
      expect(Money.new(10, "JPY")).not_to be_zero
      expect(Money.new(-1, "EUR")).not_to be_zero
    end
  end

  describe "#nonzero?" do
    it "returns whether the amount is not 0" do
      expect(Money.new(0, "USD")).not_to be_nonzero
      expect(Money.new(0, "EUR")).not_to be_nonzero
      expect(Money.new(1, "USD")).to be_nonzero
      expect(Money.new(10, "JPY")).to be_nonzero
      expect(Money.new(-1, "EUR")).to be_nonzero
    end

    it "has the same return-value semantics as Numeric#nonzero?" do
      expect(Money.new(0, "USD").nonzero?).to be_nil

      money = Money.new(1, "USD")
      expect(money.nonzero?).to be_equal(money)
    end
  end

  describe "#coerce" do
    [0, 0.0, 1, 1.0].each do |val|
      context "for #{val}" do
        %w(* / - + %).each do |op|
          it "doesnt allow #{op}" do
            expect { val.send(op, Money.usd(1)) }.to raise_error TypeError
          end
        end

        it "doesnt allow comparison" do
          expect { val < Money.usd(1) }.to raise_error ArgumentError
          expect { val >= Money.usd(1) }.to raise_error ArgumentError
        end
      end
    end
  end

  %w(+ - / <=> divmod remainder).each do |op|
    describe "##{op}" do
      subject { ->(other = self.other) { instance.send(op, other) } }
      let(:instance) { Money.usd(1) }

      context 'when conversions disallowed' do
        around do |ex|
          begin
            old = Money.default_bank
            Money.disallow_currency_conversion!
            ex.run
          ensure
            Money.default_bank = old
          end
        end

        context 'and other is money with different currency' do
          let(:other) { Money.gbp(1) }
          it { should raise_error Money::Bank::DifferentCurrencyError }

          context 'even for zero' do
            let(:instance) { Money.usd(0) }
            let(:other) { Money.gbp(0) }
            it { should raise_error Money::Bank::DifferentCurrencyError }
          end
        end
      end
    end
  end

  %w(+ - / <=> divmod remainder).each do |op|
    describe "##{op}" do
      subject { ->(other = self.other) { instance.send(op, other) } }
      let(:instance) { Money.usd(1) }

      context 'when conversions disallowed' do
        around do |ex|
          begin
            old = Money.default_bank
            Money.disallow_currency_conversion!
            ex.run
          ensure
            Money.default_bank = old
          end
        end

        context 'and other is money with different currency' do
          let(:other) { Money.gbp(1) }
          it { should raise_error Money::Bank::DifferentCurrencyError }

          context 'even for zero' do
            let(:instance) { Money.usd(0) }
            let(:other) { Money.gbp(0) }
            it { should raise_error Money::Bank::DifferentCurrencyError }
          end
        end
      end
    end
  end
end
