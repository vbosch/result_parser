module ResultParser
require 'ruby-debug'
    class ResultList
        def initialize(ex_file,ex_name)
            @file_path = ex_file
            @name = ex_name
            @results = Hash.new
            @current_batch_details = nil
            @current_experiment_details = nil
            @current_gaussians = nil
            @parse_status=:init

        end

        def read
            File.open(@file_path,"r").each_line do |line|
                parse_line(line)
            end
        end

        def parse_line(line)
           if @parse_status == :init
            if is_experiment_description_line?(line)
                @current_batch_details=extract_experiment(line)
            elsif not @current_batch_details.nil? and @current_gaussians.nil?
               if is_num_gaussians_line?(line)
                add_experiment(line)
               end 
            elsif is_sent_line?(line)
               @results[@current_experiment_details].sent_acc =  extract_sent_correct(line)
            elsif is_word_line?(line)
                @results[@current_experiment_details].word_acc =  extract_word_correct(line)
            elsif is_diffence_line?(line)   
                tmp = extract_difference_line(line)   
                @results[@current_experiment_details].mean=tmp[:mean]
                @results[@current_experiment_details].std_dev=tmp[:std_dev]
            elsif is_num_gaussians_line?(line)
                add_experiment(line)
            elsif is_separator_line?(line)
                @parse_status = :expecting_tasa_detail
            end

           elsif @parse_status == :expecting_tasa_detail or @parse_status == :tasa_detail
            if is_tasa_detail_header?(line)
                @parse_status = :tasa_detail
            elsif @parse_status == :tasa_detail and is_tasa_result_line?(line)
                tmp=extract_tasa_result(line)
                set_tasa_detail_accuracy(tmp[0],tmp[1])
            elsif @parse_status==:tasa_detail and not is_separator_line?(line)
                @parse_status = :expecting_tasa_line
            end    

           elsif @parse_status == :expecting_tasa_line or @parse_status == :tasa_line
                if @parse_status == :expecting_tasa_line and is_tasa_line_header?(line)
                    @parse_status = :tasa_line
                elsif @parse_status==:tasa_line and is_tasa_result_line?(line)
                    tmp=extract_tasa_result(line)
                    set_tasa_line_accuracy(tmp[0],tmp[1])
                elsif @parse_status==:tasa_line and not is_separator_line?(line)
                    @parse_status=:init
                    @current_experiment_details = nil
                    @current_gaussians = nil
                end  
           end           
                 

        end

        def add_experiment(line)
            @current_gaussians = extract_gaussians(line)
            @current_experiment_details = Marshal.load( Marshal.dump(@current_batch_details))
            @current_experiment_details[:gaussians]=@current_gaussians
            @results[@current_experiment_details]=Result.new(@current_experiment_details) if @results[@current_experiment_details].nil?   
        end

        def set_tasa_line_accuracy(gaussians,value)
                tmp = Marshal.load( Marshal.dump(@current_batch_details))
                tmp[:gaussians]=gaussians
                @results[tmp].tasa_line = value
        end

        def set_tasa_detail_accuracy(gaussians,value)
                tmp = Marshal.load( Marshal.dump(@current_batch_details))
                tmp[:gaussians]=gaussians
                @results[tmp].tasa_detail = value
        end

        def is_experiment_description_line?(line)
            line =~ /columns:/
        end

        def extract_experiment(line)
            data = line.split
            tmp = Hash.new
            tmp[:columns]=data[1].to_i
            tmp[:overlap]=data[3].to_i
            tmp[:states]=data[5].to_i
            tmp[:wip]= data[7].to_i
            tmp[:gsf]= data[9].to_i
            tmp[:iter]= data[11].to_i
            return tmp
        end

        def is_num_gaussians_line?(line)
            line =~ /Num gaussians:/
        end

        def extract_gaussians(line)
            return line.split[2].to_i
        end

        def is_sent_line?(line)
            line =~ /SENT:/
        end

        def extract_sent_correct(line)
            return line.split[1].split("=")[1].to_f
        end

        def is_word_line?(line)
            line =~ /WORD:/
        end

        def extract_word_correct(line)
            return line.split[2].split("=")[1].to_f
        end

        def is_diffence_line?(line)
            line =~ /Total: mean:/
        end

        def extract_difference_line(line)
            data = line.split
            tmp = Hash.new
            tmp[:mean]=data[2].to_f
            tmp[:std_dev]=data[4].to_f
            return tmp
        end

        def is_tasa_detail_header?(line)
            line =~ /TASA DETAIL RESULTS/
        end

        def is_tasa_line_header?(line)
            line =~ /TASA LINE RESULTS/
        end

        def is_separator_line?(line)
            line=~ /-------------------/
        end

        def is_tasa_result_line?(line)
            line =~ /recog/
        end

        def extract_tasa_result(line)
            data = line.split
            gaussians = data[0].match(/\d+/)[0].to_i
            return [gaussians,data[1].to_f]

        end

        def write(out_file_name)
            min = 100.0
           # out_file_name = "interactive_1col.txt"
            File.open(out_file_name,"w") do |file|
                @results.each do |key,result|
                  #if result.mean < 7.05 and result.experiment_parameters[:wip]==-128 and result.experiment_parameters[:columns]==2
                    file.puts result.to_s 
                    if not result.tasa_detail.nil? and 100-result.tasa_detail < min
                     min = 100-result.tasa_detail 
                     puts result.experiment_parameters
                    end
                 # end
                end
             end
             puts min
        end

    end
end
