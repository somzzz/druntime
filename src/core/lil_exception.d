module lil_exception;

// Compiler lowers final switch default case to this (which is a runtime error)
void _d_assert_msgT()(string msg, string file, uint line) @trusted pure
{
    static bool hasHandler()
    {
        return !!_assertHandler;
    }

    static void callHandler(string file, uint line, string msg)
    {
        (cast(void function(string, size_t, string) pure nothrow @nogc) &_assertHandler)(file, line, msg);
    }
    
    if (!(cast(bool function() pure nothrow @nogc) &hasHandler)())
        throw staticError!AssertError(msg, file, line);
    else
        (cast(void function(string, size_t, string) pure nothrow @nogc) &callHandler)(file, line, msg);
}