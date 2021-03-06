defmodule CparserTest do
  use ExUnit.Case

  test "comment" do
    # single comment
    construct = Cparser.get_construct("//this is a comment")
    assert construct === :ignore

    #multi line open comment
    construct = Cparser.get_construct("/*tis is a comment")
    assert construct === :ignore
    construct = Cparser.get_construct("*this is a comment")
    assert construct === :ignore
    construct = Cparser.get_construct("this is a comment*/")
    assert construct === :ignore

  end

  test "include" do
    construct = Cparser.get_construct("#include <iostream>")
    assert construct === :ignore
  end

  test "forward declaration" do
    construct = Cparser.get_construct("/*FD*/ namespace forward_declared {")
    assert construct === :ignore
  end

  test "class forward declared" do
    construct = Cparser.get_construct("class forward_declared;")
    assert construct === :ignore
  end

  test "namespace" do
    construct = Cparser.get_construct("namespace rewire {")
    assert construct === :namespace
  end

  test "class" do
    construct = Cparser.get_construct("class myclass {")
    assert construct === :class
  end

  test "class templates" do
    construct = Cparser.get_construct("class HabitDataHolder : public Applib::DataHolder<Habit,HabitFilter> {")
    assert construct === :class_template
  end

  test "constructor" do
    construct = Cparser.get_construct("myclass();")
    assert construct === :constructor
  end

  test "const function" do

    #const return type
    construct = Cparser.get_construct("const type func(const type var1, type var2);");
    assert construct === :ignore

    #const function
    construct = Cparser.get_construct("type func(const type* var1, type var2) const;");
    assert construct === :ignore

  end

  test "pure virtual function" do
    construct = Cparser.get_construct("virtual type func(type var1, type var2) = 0;");
    assert construct === :ignore
  end

  test "virtual function" do
    construct = Cparser.get_construct("virtual type func(type var1, type var2);");
    assert construct === :function
  end

  test "destructor" do
    construct = Cparser.get_construct("~myclass();")
    assert construct === :ignore
  end

  test "parse typenames" do
    typenames = Cparser.parse_typenames("class CategoryManager : public Applib::Items::ItemManager<Category, CategoryFilter, RewireApp,CategoryDataHolder>")
    assert typenames === ["Category","CategoryFilter","RewireApp","CategoryDataHolder"]
  end

  test "parse class name" do
    class = Cparser.parse_class("class HabitDataHolder : public Applib::DataHolder<Habit,HabitFilter> {")
    assert class === "HabitDataHolder"
  end

  test "parse return type" do
    #normal
    return_type = Cparser.parse_returntype("void test_function1(int param1,int* param2, const std::string& param3);")
    assert return_type == ReturnType.new("void",false)

    #pointer
    return_type = Cparser.parse_returntype("std::string* test_function1(int param1,int* param2, const std::string& param3);")
    assert return_type == ReturnType.new("std::string",true)

  end

  test "parse parameters params" do
    params = Cparser.parse_params("void test_function1(int param1,int* param2,int& param3,const int param4,const int* param5, const int& param6);")
    #assert return_type == ReturnType.new("void",false)

    assert params === [Param.new("int","param1",false,false,false),
                       Param.new("int","param2",true,false,false),
                       Param.new("int","param3",false,true,false),
                       Param.new("int","param4",false,false,true),
                       Param.new("int","param5",true,false,true),
                       Param.new("int","param6",false,true,true)
                       ]
  end


  test "parse function" do
    function = Cparser.parse_function("void test_function1(int param1,int* param2, const std::string& param3);",Interface.new())

    #return type
    params = [Param.new("int","param1",false,false,false),
              Param.new("int","param2",true,false,false),
              Param.new("std::string","param3",false,true,true)]

    assert function == Func.new(ReturnType.new("void",false),"test_function1",params,false)

  end

  test "parse function that disowns memory" do
    interace = Interface.new()
    interace = Interface.add_disown_memory(interace,"void test_function1(int param1,int* param2, const std::string& param3);")
    function = Cparser.parse_function("void test_function1(int param1,int* param2, const std::string& param3);",interace)

    #return type
    params = [Param.new("int","param1",false,false,false),
              Param.new("int","param2",true,false,false),
              Param.new("std::string","param3",false,true,true)]

    assert function == Func.new(ReturnType.new("void",false,true),"test_function1",params,false)

  end

  test "static getInstance function disowns memory" do
    function = Cparser.parse_function("static Data* getInstance(int param1,int* param2, const std::string& param3);",Interface.new())

    #return type
    params = [Param.new("int","param1",false,false,false),
              Param.new("int","param2",true,false,false),
              Param.new("std::string","param3",false,true,true)]

    assert function == Func.new(ReturnType.new("Data",true,true),"getInstance",params,true)
  end

  test "getRef function disowns memory" do
    function = Cparser.parse_function("Data* getRef(int param1,int* param2, const std::string& param3);",Interface.new())

    #return type
    params = [Param.new("int","param1",false,false,false),
              Param.new("int","param2",true,false,false),
              Param.new("std::string","param3",false,true,true)]

    assert function == Func.new(ReturnType.new("Data",true,true),"getRef",params,false)
  end

  test "parse static const function" do

  end

  test "parse real source " do

    source = " #ifndef TEST_H
               #define TEST_H

               /*FD*/ namespace forward_namespace {
                   class test_class;
               }

               namespace test_namespace {
                   class test_class {
                       public:
                          test_class(const std::string& param1, int param2, Date* param3);

                          Data* function1(int param1, int* param2, int& param3, const int* param4, const int& param5);

                          static int function2(const Namespace2::Data& data);

                       private:
                          int mPram1;
                          int mParam2;

                   };
               }

             "

     ast = Cparser.build_ast(source,Interface.new())

     model_ast = %Ast{}
                 |> Ast.setNamespace("test_namespace")
                 |> Ast.setClass("test_class")
                 |> Ast.addConstructor(Constructor.new([Param.new("std::string","param1",false,true,true),
                                                                         Param.new("int","param2",false,false,false),
                                                                         Param.new("Date","param3",true,false,false)]))

                 |> Ast.addFunction(Func.new(ReturnType.new("Data",true),"function1",[Param.new("int","param1",false,false,false),
                                                                                            Param.new("int","param2",true,false,false),
                                                                                            Param.new("int","param3",false,true,false),
                                                                                            Param.new("int","param4",true,false,true),
                                                                                            Param.new("int","param5",false,true,true)],false))
                 |> Ast.addFunction(Func.new(ReturnType.new("int",false),"function2",[Param.new("Namespace2::Data","data",false,true,true)],true))
                 |> Ast.setHasReachedStop(true)


     assert ast === model_ast


  end

  test "update ast parent" do

   ast = %Ast{}
           |> Ast.setNamespace("test_namespace")
           |> Ast.setClass("test_class")
           |> Ast.addConstructor(Constructor.new([Param.new("std::string","param1",false,true,true),
                                                  Param.new("int","param2",false,false,false),
                                                  Param.new("Date","param3",true,false,false)]))

           |> Ast.addFunction(Func.new(ReturnType.new("Data",true),"function1",[Param.new("int","param1",false,false,false),
                                                                                Param.new("int","param2",true,false,false),
                                                                                Param.new("int","param3",false,true,false),
                                                                                Param.new("int","param4",true,false,true),
                                                                                Param.new("int","param5",false,true,true)],false))
           |> Ast.addFunction(Func.new(ReturnType.new("int",false),"function2",[Param.new("Namespace2::Data","data",false,true,true)],true))
           |> Ast.setHasReachedStop(true)

    source = " #ifndef TEST_H
               #define TEST_H

               /*FD*/ namespace forward_namespace {
                   class forward_class;
               }

               namespace parent_namespace {
                   class parent_class {
                       public:
                          parent_class(const std::string& param1, int param2, Date* param3);

                          Data* function_parent(int param1);

                          Data* function1(int param1, int* param2, int& param3, const int* param4, const int& param5);

                          static int function2(const Namespace2::Data& data);

                       private:
                          int mPram1;
                          int mParam2;

                   };
               }

             "

     updated_ast = Cparser.build_ast_parent(ast,source,Interface.new())

     ast = ast |> Ast.addFunction(Func.new(ReturnType.new("Data",true),"function_parent",[Param.new("int","param1",false,false,false)],false))

     assert updated_ast === ast


  end





end
