module Danger
  class Interviewer
    attr_accessor :no_delay, :no_waiting, :ui

    def initialize(cork_board)
      @ui = cork_board
    end

    def show_prompt
      ui.print "> ".bold.green
    end

    def yellow_bang
      "! ".yellow
    end

    def green_bang
      "! ".green
    end

    def red_bang
      "! ".red
    end

    def say(output)
      ui.puts output
    end

    def header(title)
      say title.yellow
      say ""
      pause 0.6
    end

    def link(url)
      say " -> " + url.underlined + "\n"
    end

    def pause(time)
      sleep(time) unless @no_waiting
    end

    def wait_for_return
      STDOUT.flush
      STDIN.gets unless @no_delay
      ui.puts
    end

    def run_command(command, output_command = nil)
      output_command ||= command
      ui.puts "  " + output_command.magenta
      system command
    end

    def ask_with_answers(question, possible_answers)
      ui.print "\n#{question}? ["

      print_info = proc do
        possible_answers.each_with_index do |answer, i|
          the_answer = i.zero? ? answer.underlined : answer
          ui.print " " + the_answer
          ui.print(" /") if i != possible_answers.length - 1
        end
        ui.print " ]\n"
      end
      print_info.call

      answer = ""

      loop do
        show_prompt
        answer = @no_waiting ? possible_answers[0].downcase : STDIN.gets.downcase.chomp

        answer = "yes" if answer == "y"
        answer = "no" if answer == "n"

        # default to first answer
        if answer == ""
          answer = possible_answers[0].downcase
          ui.puts "Using: " + answer.yellow
        end

        break if possible_answers.map(&:downcase).include? answer

        ui.print "\nPossible answers are ["
        print_info.call
      end

      answer
    end
  end
end
