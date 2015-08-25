module Suadeo
  class Recommender
    def initialize(data:, subject:, similarity: 'Pearson')
      @data = data
      @subject = subject
      @similarity = similarity
      @similarity_scores = {}
      @totals = {}
      @sim_sums = {}
      @totals.default = 0
      @sim_sums.default = 0
    end

    def is_subject?(comperate)
      comperate == @subject
    end

    def score(comperate)
      return @similarity_scores[comperate] if @similarity_scores && @similarity_scores[comperate]
      @similarity_scores[comperate] = similarity_calculator.new(data: @data, p1: @subject, p2: comperate).calc
    end

    def similarity_calculator
      Module.const_get("Suadeo::#{@similarity}Calculator")
    end

    def non_positive_similarity?(comperate)
      score(comperate) <= 0
    end

    def scored_by_subject?(subject, product)
      if @data[subject][product]
        !@data[subject][product].zero?  || @data[subject].include?(product)
      end
    end

    def update_sums(comperate, product)
      @totals[product] += @data[comperate][product] * score(comperate)
      @sim_sums[product] += score(comperate)
    end

    def recs
      @data.each_key do |comperate|
        next if is_subject?(comperate) || non_positive_similarity?(comperate)
        @data[comperate].each_key do |product|
          update_sums(comperate, product) unless scored_by_subject?(@subject, product)
        end
      end
      rankings
    end

    def rankings
      rankings = {}
      @totals.each { |subject, total| rankings[subject] = total / @sim_sums[subject] }
      rankings.sort_by{|k, v| v}.reverse
    end
  end
end