defmodule JavaGenerator do
  @moduledoc false


  #generate class
  def generate_class(ast) do
    template = "class %class_name% {

                   %constructors%

                   %functions%

                }"

     template
      |> String.replace("%class_name%",Ast.get_class(ast))
      |> String.replace("%constructors%",generate_constructors(Ast.get_constructors(ast),Ast.get_class(ast)))
      |> String.replace("%functions%",generate_functions(Ast.get_functions(ast)))

  end

  #constructor list
  def generate_constructors(constructors_list,class_name) do
    Enum.reduce(constructors_list,"",fn(x,acc) -> acc <> "\n" <> generate_constructor(x,class_name) end ) |> String.replace("\n","",global: :false)
  end

  #constructor
  def generate_constructor(constructor,class_name) do
    "public %class_name%(%params%);"
     |> String.replace("%class_name%",class_name)
     |> String.replace("%params%",generate_params(Constructor.get_params(constructor)))
  end

  #functions list
  def generate_functions(functions_list) do
    Enum.reduce(functions_list,"",fn(x,acc) -> acc <> "\n" <> generate_func(x) end ) |> String.replace("\n","",global: :false)
  end

  #generic function
  def generate_func(func) do

    case Func.is_static?(func) do
      true  -> generate_static_func(func)
      false -> generate_normal_func(func)
    end

  end

  #function
  def generate_normal_func(func) do

    template = " %returnType% %functionName%(%params_list%);"

    #member function
    member_function = template
                    |> String.replace("%returnType%",Func.returnType(func) |> generate_returntype)
                    |> String.replace("%functionName%",Func.name(func))
                    |> String.replace("%params_list%",generate_params(Func.params(func)))


    #add param for static version
    params = [Param.new("long","CPointer",false,false,false) | Func.params(func)]
    func = Func.setParams(func,params)


    #static member function
    static_member_function = template
                            |> String.replace("%returnType%",Func.returnType(func) |> generate_returntype)
                            |> String.replace("%functionName%",Func.name(func))
                            |> String.replace("%params_list%",generate_params(Func.params(func)))

    #combine the two functions
    "public %member_func%
     public static %static_member_func%"
     |> String.replace("%member_func%",member_function)
     |> String.replace("%static_member_func%",static_member_function)

  end

  #generate static function
  def generate_static_func(func) do

    #generate parameters string
    param_str = Enum.reduce(Func.params(func),"",fn(x,acc) -> acc <> "," <> generate_param(x) end )
                |> String.replace(",","",global: :false)

    #fill the template
    "public static %returnType% %functionName%(%params_list%);"
     |> String.replace("%returnType%",Func.returnType(func) |> generate_returntype)
     |> String.replace("%functionName%",Func.name(func))
     |> String.replace("%params_list%",param_str)

  end

  #Params
  def generate_params(params_list) do
    Enum.reduce(params_list,"",fn(x,acc) -> acc <> "," <> generate_param(x) end ) |> String.replace(",","",global: :false)
  end

  #Param
  def generate_param(param) do
     template = "%typeName% %varName%"

     typeName = Param.typeName(param)

     typeName = cond do
                  #String
                  typeName === "string" -> "String"

                  #No match
                  true -> typeName
                end

     template
        |> String.replace("%typeName%",typeName)
        |> String.replace("%varName%",Param.varName(param))

  end

  #return type
  def generate_returntype(return_type) do

      cond do
         ReturnType.name(return_type) === "string" -> "String"
         true -> ReturnType.name(return_type)
      end

  end

  
end