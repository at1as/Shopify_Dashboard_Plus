# frozen_string_literal: true

# When adding 44.95.round(2) + 940.6.round(2) the precision of the result will be 985.5500000000001
# In a sample of 100_000_000_000 entries, the precision will round up cents
# Since all numbers are currency, the plus method will trim to two decimals
# Numbers returned as: 44, 44.5, or 44.51
# Note that Numbers are class Fixnum in Ruby < 2.4 and Integer from 2.4 onwards
module Currency  
  if 0.class.to_s == "Fixnum"
    refine Fixnum do
      def plus(amount)
        result = self + (amount.to_f rescue 0)
        result.round(2)
      end
    end
  else
    refine Integer do
      def plus(amount)
        result = self + (amount.to_f rescue 0)
        result.round(2)
      end
    end
  end

  refine Float do
    def plus(amount)
      result = self + (amount.to_f rescue 0)
      result.round(2)
    end
  end
end
