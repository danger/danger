module Danger
  class Interviewer
    def show_prompt
      print " > ".green
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
      puts output
    end

    def pause(time)
      sleep(time)
    end

    def wait

    def run_command(command, output_command = nil)
      output_command ||= command
      puts "  " + output_command.magenta
      system command
    end

    def ask(question)
      answer = ""
      loop do
        puts "\n#{question}?"

        show_prompt
        answer = gets.chomp

        break if answer.length > 0

        print "\nYou need to provide an answer."
      end
      answer
    end

    def ask_with_answers(question, possible_answers)
      print "\n#{question}? ["

      print_info = proc do
        possible_answers.each_with_index do |answer, i|
          the_answer = (i == 0) ? answer.underline : answer
          print " " + the_answer
          print(" /") if i != possible_answers.length - 1
        end
        print " ]\n"
      end
      print_info.call

      answer = ""

      loop do
        show_prompt
        answer = gets.downcase.chomp

        answer = "yes" if answer == "y"
        answer = "no" if answer == "n"

        # default to first answer
        if answer == ""
          answer = possible_answers[0].downcase
          print answer.yellow
        end

        break if possible_answers.map(&:downcase).include? answer

        print "\nPossible answers are ["
        print_info.call
      end

      answer
    end
  end
end
