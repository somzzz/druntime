module lil_exception;


// NOTE: One assert handler is used for all threads.  Thread-local
//       behavior should occur within the handler itself.  This delegate
//       is __gshared for now based on the assumption that it will only
//       set by the main thread during program initialization.
public __gshared AssertHandler _assertHandler = null;

/**
Gets/sets assert hander. null means the default handler is used.
*/
alias AssertHandler = void function(string file, size_t line, string msg) nothrow @nogc;


// TLS storage shared for all errors, chaining might create circular reference
private void[128] _store;


// only Errors for now as those are rarely chained
public T staticError(T, Args...)(auto ref Args args)
    if (is(T : Error))
{
    // pure hack, what we actually need is @noreturn and allow to call that in pure functions
    static T get()
    {
        static assert(__traits(classInstanceSize, T) <= _store.length,
                      T.stringof ~ " is too large for staticError()");

        _store[0 .. __traits(classInstanceSize, T)] = typeid(T).initializer[];
        return cast(T) _store.ptr;
    }
    auto res = (cast(T function() @trusted pure nothrow @nogc) &get)();
    res.__ctor(args);
    return res;
}

/**
 * Thrown on an assert error.
 */
class AssertError : Error
{
    @safe pure nothrow @nogc this( string file, size_t line )
    {
        this(cast(Throwable)null, file, line);
    }

    @safe pure nothrow @nogc this( Throwable next, string file = __FILE__, size_t line = __LINE__ )
    {
        this( "Assertion failure", file, line, next);
    }

    @safe pure nothrow @nogc this( string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null )
    {
        super( msg, file, line, next );
    }
}

unittest
{
    {
        auto ae = new AssertError("hello", 42);
        assert(ae.file == "hello");
        assert(ae.line == 42);
        assert(ae.next is null);
        assert(ae.msg == "Assertion failure");
    }

    {
        auto ae = new AssertError(new Exception("It's an Exception!"));
        assert(ae.file == __FILE__);
        assert(ae.line == __LINE__ - 2);
        assert(ae.next !is null);
        assert(ae.msg == "Assertion failure");
    }

    {
        auto ae = new AssertError(new Exception("It's an Exception!"), "hello", 42);
        assert(ae.file == "hello");
        assert(ae.line == 42);
        assert(ae.next !is null);
        assert(ae.msg == "Assertion failure");
    }

    {
        auto ae = new AssertError("msg");
        assert(ae.file == __FILE__);
        assert(ae.line == __LINE__ - 2);
        assert(ae.next is null);
        assert(ae.msg == "msg");
    }

    {
        auto ae = new AssertError("msg", "hello", 42);
        assert(ae.file == "hello");
        assert(ae.line == 42);
        assert(ae.next is null);
        assert(ae.msg == "msg");
    }

    {
        auto ae = new AssertError("msg", "hello", 42, new Exception("It's an Exception!"));
        assert(ae.file == "hello");
        assert(ae.line == 42);
        assert(ae.next !is null);
        assert(ae.msg == "msg");
    }
}
