defmodule Cparser do

  #read the source and build an ast from it
  def build_ast(source) do
    statements = Enum.reduce(String.split(source,"\n"),[],&(check_and_add(&1,&2))) |> Enum.reverse

    #build the ast
    Enum.reduce(statements,%Ast{},&(update_ast(&1,&2)))

  end

  def update_ast(statement,ast) do

      case Ast.hasReachedStop?(ast) do
         :true -> ast

         :false -> case get_construct(statement,ast) do

                       #ignore
                       :ignore -> ast

                       #namespace
                       :namespace -> Ast.setNamespace(ast,parse_namespace(statement))

                       #class
                       :class -> Ast.setClass(ast,parse_class(statement))

                       #constructor
                       :constructor -> Ast.addConstructor(ast,parse_constructor(statement))

                        #function
                       :function -> Ast.addFunction(ast,parse_function(statement))

                       #private
                       :private -> Ast.setHasReachedStop(ast,true);

                       #protected
                       :protected -> Ast.setHasReachedStop(ast,true);

                       _ -> ast
                 end
      end

  end

  #read the line and return the construct the line represents
  def get_construct(line,ast) when byte_size(line) > 0  do
        #remove semicolon
        line = String.replace(line, ";","")
        cond do
          #empty line
          String.length(line) === 0 -> :ignore

          #include
          String.split(line) |> Enum.at(0) === "#include" -> :ignore

          #forward declaration
          String.contains?(line,"/*FD*/") -> :ignore

          #comment
          String.contains?(line,"//") ||
          String.contains?(line,"/*") ||
          String.contains?(line,"*/") ||
          String.at(line,0) === "*" -> :ignore

          #namespace
          String.split(line) |> Enum.at(0) === "namespace" -> :namespace

          #class
          String.split(line) |> Enum.at(0) === "class" && String.last(line) === "{" -> :class

          #constructor
          String.contains?(line,"(") && String.contains?(line,")") &&
          ast.class !== "" && String.split(line,"(") |> Enum.at(0) === ast.class -> :constructor

          #destructors
          String.contains?(line,"~") -> :ignore

          #pure virtual functions
          String.contains?(line,"virtual") && String.contains?(line,"=") -> :ignore

          #function
          String.contains?(line,"(") && String.contains?(line,")") ->
            cond do
              function_const?(line) -> :ignore
              true -> :function
            end

          #private
          String.contains?(line,"private:") -> :private

          #protected
          String.contains?(line,"protected:") -> :protected

          #nothing matches
          true -> :ignore

        end
  end

  #check if statement is empty and if not add to list
  defp check_and_add(statement,list) do
    statement = String.strip(statement)
    case String.length(statement) > 0 do
      :true -> [statement | list]
      :false -> list
    end
  end

  #check if the function is const
  defp function_const?(line) do
    words = String.split(line)
    cond do
      Enum.at(words,0) === "const" || Enum.at(words,length(words) - 1) === "const" -> :true
      true -> :false
    end
  end

  defp parse_namespace(statement) do
      String.replace(statement,"namespace","", global: false) |> String.replace("{","") |> String.strip
  end

  defp parse_class(statement) do
    String.replace(statement,"class","",global: false) |> String.replace("{","") |> String.strip
  end

  def parse_constructor(statement) do
    #paramaters
    params = parse_params(statement)

    Constructor.new(params)

  end

  def parse_function(statement) do

    #return type
    returnType = parse_returntype(statement)

    #is static
    is_static = String.contains?(statement,"static ")

    #name
    name = String.replace(statement,"("," ") |> String.replace(")"," ") |>  String.split(" ") |> Enum.at(case is_static do
                                                                                                             false-> 1
                                                                                                             true -> 2
                                                                                                         end)

    #paramaters
    params = parse_params(statement)

    Func.new(returnType,name,params,is_static)

  end

  def parse_returntype(statement) do
    is_static = String.contains?(statement,"static ")
    word = String.split(statement," ") |> Enum.at(case is_static do
                                                    false -> 0
                                                    true -> 1
                                                  end)
    is_pointer = String.contains?(word,"*")
    ReturnType.new(String.replace(word,"*",""),is_pointer)
  end

  def parse_params(statement) do
    statement = String.replace(statement,";","")
    [_,params_left] = String.split(statement,"(")
    [params_right,_] = String.split(params_left,")")

    raw_params = String.split(params_right,",", trim: true)

    Enum.reduce(raw_params,[],fn(raw_param,params) -> [parse_raw_param(raw_param)| params] end) |> Enum.reverse

  end

  defp parse_raw_param(raw_param) do
    #remove white spaces
    raw_param = String.strip(raw_param)

    is_pointer = String.contains?(raw_param,"*")
    is_reference = String.contains?(raw_param,"&")
    is_const = String.contains?(raw_param,"const ")

    #split so that we can extract type and name
    words = String.split(raw_param," ")

    param = cond do
              is_const && is_pointer    -> Param.new(String.replace(Enum.at(words,1),"*",""),Enum.at(words,2),true,false,true)
              !is_const && is_pointer   -> Param.new(String.replace(Enum.at(words,0),"*",""),Enum.at(words,1),true,false,false)
              is_const && is_reference  -> Param.new(String.replace(Enum.at(words,1),"&",""),Enum.at(words,2),false,true,true)
              !is_const && is_reference -> Param.new(String.replace(Enum.at(words,0),"&",""),Enum.at(words,1),false,true,false)
              true                      -> Param.new(Enum.at(words,0),Enum.at(words,1),false,false,false)
            end

    param_type_name = case String.contains?(Param.typeName(param),"::") do
                          true -> String.split(Param.typeName(param),"::") |> Enum.reverse() |> Enum.at(0)
                          false -> Param.typeName(param)
                      end


    Param.setTypeName(param,param_type_name)

  end

end
