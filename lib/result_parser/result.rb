module ResultParser
    require 'ruby-debug'
    class Result

        attr_accessor :mean, :std_dev, :tasa_line, :tasa_detail, :sent_acc, :word_acc, :experiment_parameters
        def initialize(ex_params)
            @experiment_parameters=ex_params
        end

        def to_s
            tmp = @experiment_parameters.inject(""){|res,(k,v)|res += "#{v} " }
            tmp +="#{100.0-@sent_acc} " unless @sent_acc.nil?
            tmp +="#{100.0-@word_acc} " unless @word_acc.nil?
            tmp +="#{@mean} "
            tmp +="#{@std_dev} "
            tmp +="#{100.0 - @tasa_line} " unless @tasa_line.nil?
            tmp +="#{100.0 - @tasa_detail} " unless @tasa_detail.nil?
            return tmp
        end
    end
end