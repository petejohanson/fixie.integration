﻿namespace Static.Tests
{
    using Fixie.Integration;
    using Shouldly;

    public static class CalculatorTests
    {
        public static void ShouldAdd() => new Calculator().Add(2, 3).ShouldBe(5);

        public static void ShouldSubtract() => new Calculator().Subtract(5, 3).ShouldBe(2);
    }
}