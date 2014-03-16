require 'colored'

class Generator

  class << self

    def run
      get_constants

      @cycles.to_i.times do
        @file.puts '='*10
        generate_next_state
      end

      puts "States probabilities:".green
      @states.each do |state, count|
        puts "P#{state}".red + ' =' + " #{count/@cycles.to_f}".cyan
        @states[state] = count/@cycles.to_f
      end

      puts "System performance metrics:".green
      puts "Average queue length per cycle: ".red + "#{@queue_processed/@cycles.to_f}".cyan
      puts "Average requests processed per cycle: ".red + "#{@services_count/(@cycles.to_f*2)}".cyan
    end


    private

    def get_constants
      @p = ARGV[0].to_f === 0.00001..1e7 ? ARGV[0].to_f : 0.75
      @p1 = ARGV[0].to_f === 0.00001..1e7 ? ARGV[1].to_f : 0.8
      @p2 = ARGV[0].to_f === 0.00001..1e7 ? ARGV[2].to_f : 0.5
      @cycles = ARGV[0].to_f === 1..1e7 ? ARGV[3].to_f : 10000

      @file = File.open("lab3_states.txt", "w")

      @states = {"0000" => 1,
                 "0001" => 0,
                 "0010" => 0,
                 "0011" => 0,
                 "0111" => 0,
                 "0211" => 0,
                 "1211" => 0
      }

      @current_state = '0000'
      @file.puts @current_state

      @queue_processed = 0
      @services_count = 0
    end

    def chanel_1_busy?
      rand <= @p1
    end

    def chanel_2_busy?
      rand <= @p2
    end

    def count_state
      @states[@current_state] += 1
    end

    def request?
      return false if @current_state[0] == 1
      rand <= (1 - @p)
    end

    def generate_next_state
      generator_state = @current_state[0].to_i
      queue = @current_state[1].to_i
      channel_1_state = @current_state[2].to_i
      channel_2_state = @current_state[3].to_i

      channel_1_state = (channel_1_state == 1 && chanel_1_busy?) ? 1 : 0
      channel_2_state = (channel_2_state == 1 && chanel_2_busy?) ? 1 : 0

      if queue > 0
        if channel_1_state == 0
          queue -= 1
          channel_1_state = 1
        end

        if channel_2_state == 0 && queue > 0
          queue -= 1
          channel_2_state = 1
        end
      end

      if generator_state == 1 && queue <= 1
        generator_state = 0
        @current_state[0] = 0.to_s
        queue += 1
      end


      if request?
        if channel_1_state == 0
          channel_1_state = 1
        elsif channel_2_state == 0
          channel_2_state = 1
        elsif queue <= 1
          queue += 1
        elsif generator_state == 0
          generator_state = 1
        end
      end

      @queue_processed += queue
      @services_count += (channel_1_state + channel_2_state)

      @current_state = "#{generator_state}#{queue}#{channel_1_state}#{channel_2_state}"
      @file.puts @current_state

      count_state
    end

  end
end

Generator.run