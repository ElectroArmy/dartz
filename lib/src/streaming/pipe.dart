part of dartz_streaming;

class From<A> {}

class Pipe {
  static final From _get = new From();

  static Conveyor<From/*<I>*/, dynamic/*=O*/> produce/*<I, O>*/(/*=O*/ h, [Conveyor/*<From<I>, O>*/ t]) =>
      Conveyor.produce(h, t);

  static Conveyor<From/*<I>*/, dynamic/*=O*/> consume/*<I, O>*/(Function1/*<I, Conveyor<From<I>, O>>*/ recv, [Function0/*<Conveyor<From<I>, O>>*/ fallback]) =>
      Conveyor.consume(_get as dynamic/*=From<I>*/, (ea) => ea.fold(
          (err) => err == Conveyor.End ? (fallback == null ? halt() : fallback()) : Conveyor.halt(err)
      ,(/*=I*/ i) => Conveyor.Try(() => recv(i))));

  static Conveyor<From/*<I>*/, dynamic/*=O*/> halt/*<I, O>*/() => Conveyor.halt(Conveyor.End);

  static Conveyor<From/*<I>*/, dynamic/*=I*/> identity/*<I>*/() => lift(id);

  static Conveyor<From/*<I>*/, dynamic/*=O*/> lift/*<I, O>*/(Function1/*<I, O>*/ f) => consume/*<I, O>*/((i) => produce(f(i))).repeatUntilExhausted();

  static Conveyor<From/*<I>*/, dynamic/*=I*/> take/*<I>*/(int n) => n <= 0 ? halt() : consume((i) => produce(i, take/*<I>*/(n-1)));

  static Conveyor<From/*<I>*/, dynamic/*=I*/> takeWhile/*<I>*/(bool f(/*=I*/ i)) => consume((i) => f(i) ? produce(i, takeWhile/*<I>*/(f)) : halt());

  static Conveyor<From/*<I>*/, dynamic/*=I*/> drop/*<I>*/(int n) => consume((i) => n > 0 ? drop/*<I>*/(n-1) : produce(i, identity()));

  static Conveyor<From/*<I>*/, dynamic/*=I*/> dropWhile/*<I>*/(bool f(/*=I*/ i)) => consume((i) => f(i) ? dropWhile/*<I>*/(f) : identity());

  static Conveyor<From/*<I>*/, dynamic/*=I*/> filter/*<I>*/(bool f(/*=I*/ i)) => consume/*<I, I>*/((i) => f(i) ? produce(i) : halt()).repeatUntilExhausted();

  static Conveyor<From/*<I>*/, dynamic/*=O*/> scan/*<I, O>*/(/*=O*/ z, Function2/*<O, I, O>*/ f) {
    Conveyor/*<From<I>, O>*/ go(/*=O*/ previous) => consume((/*=I*/ i) {
      final current = f(previous, i);
      return produce(current, go(current));
    });
    return go(z);
  }

  static Conveyor<From/*<I>*/, dynamic/*=I*/> intersperse/*<I>*/(/*=I*/ sep) => Pipe.consume/*<I, I>*/((i) => Pipe.produce(i, Pipe.produce(sep))).repeatUntilExhausted();

  static Conveyor<From/*<I>*/, Tuple2/*<Option<I>, I>*/> window2/*<I>*/() {
    Conveyor<From/*<I>*/, Tuple2/*<Option<I>, I>*/> go(Option/*<I>*/ prev) =>
        Pipe.consume/*<I, Tuple2<Option<I>, I>>*/((/*=I*/ i) => Pipe.produce/*<I, Tuple2<Option<I>, I>>*/(tuple2(prev, i)).lazyPlus(() => go(some(i))));
    return go(none());
  }

  static Conveyor<From/*<I>*/, Tuple2/*<I, I>*/> window2All/*<I>*/() => window2/*<I>*/().flatMap((t) => t.value1.fold(halt, (v1) => produce(tuple2(v1, t.value2))));

  static Conveyor/*<From<A>, A>*/ buffer/*<A>*/(Monoid/*<A>*/ monoid, int n) {
    Conveyor/*<From<A>, A>*/ go(int i, /*=A*/ sofar) =>
        Pipe.consume(
            (a) => i > 1 ? go(i-1, monoid.append(sofar, a)) : Pipe.produce(monoid.append(sofar, a), go(n, monoid.zero()))
            ,() => sofar == monoid.zero() ? Pipe.halt() : Pipe.produce(sofar));
    return go(n, monoid.zero());
  }

  static Conveyor<From/*<A>*/, dynamic/*=A*/> skipDuplicates/*<A>*/([Eq/*<A>*/ _eq]) {
    final Eq/*<A>*/ eq = _eq ?? ObjectEq;
    Conveyor<From/*<A>*/, dynamic/*=A*/> loop(/*=A*/ lastA) =>
        Pipe.consume((/*=A*/ a) => eq.eq(lastA, a) ? loop(lastA) : Pipe.produce(a, loop(a)));
    return Pipe.consume((/*=A*/ a) => Pipe.produce(a, loop(a)));
  }
}