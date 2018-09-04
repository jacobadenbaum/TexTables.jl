@testset "Check Constructor" begin

    @testset "No SE" begin
        for x in [1, .1, "1", π]
            @test FormattedNumber(x).val == x
            @test FormattedNumber(x).star == 0
        end
        @test FormattedNumber(1).format     == "{:,n}"
        @test FormattedNumber(.1).format    == "{:.3f}"
        @test FormattedNumber(1e-3).format  == "{:.3f}"
        @test FormattedNumber(1e-4).format  == "{:.3e}"
        @test FormattedNumber(1e3).format   == "{:.3f}"
        @test FormattedNumber(1e6).format   == "{:.3e}"

        @test_throws ErrorException FormattedNumber(Complex(1, 1))
    end

    @testset "SE" begin
        for x in [1, "1"]
            @test_throws AssertionError FormattedNumber(x, .2)
        end

        @test FormattedNumber(1.0, 0.1).format    == "{:.3f}"
        @test FormattedNumber(1.0, 0.1).format_se == "{:.3f}"

        @test FormattedNumber(1.0e4, 0.1).format    == "{:.3f}"
        @test FormattedNumber(1.0e4, 0.1).format_se == "{:.3f}"

        @test FormattedNumber(1.0e5, 0.1).format    == "{:.3e}"
        @test FormattedNumber(1.0e5, 0.1).format_se == "{:.3f}"

        @test FormattedNumber(1.0e-4, 0.1).format    == "{:.3e}"
        @test FormattedNumber(1.0e-4, 0.1).format_se == "{:.3f}"

        @test FormattedNumber(1.0, 1e4).format_se  == "{:.3f}"
        @test FormattedNumber(1.0, 1e5).format_se  == "{:.3e}"

        @test FormattedNumber(1.0, 1e-3).format_se  == "{:.3f}"
        @test FormattedNumber(1.0, 1e-4).format_se  == "{:.3e}"

        x = FormattedNumber(1.0, .1)
        @test x.val  == 1.0
        @test x.se   == 0.1
        @test x.star == 0
        star!(x, 1)
        @test x.star == 1

        # Check automatic conversion to FNumSE
        @testset "Promotion"  begin
            x = FormattedNumber(1.0)
            y = FormattedNumber(1.0, 0.1)

            x1, y1 = promote(x, y)
            @test y1 == y
            @test x1.val == x.val
            @test isnan(x1.se)
        end
    end
end

@testset "Showing Formatted Numbers" begin

    @test sprint(show, FormattedNumber(.1)) == "0.100"
    @test sprint(show, FormattedNumber(1)) == "1"
    @test sprint(show, FormattedNumber("test")) == "test"
    @test sprint(show, FormattedNumber(true)) == "true"

    @test sprint(show, FormattedNumber(1.0, 0.1))   == "1.000 (0.100)"
    @test sprint(show, FormattedNumber(1.0, 1e-3))  == "1.000 (0.001)"
    @test sprint(show, FormattedNumber(1.0, 1e-4))  == "1.000 (1.000e-04)"
    @test sprint(show, FormattedNumber(1.0, 1e4))   == "1.000 (10000.000)"
    @test sprint(show, FormattedNumber(1.0, 1e5))   == "1.000 (1.000e+05)"

    @test sprint(show, FormattedNumber(1.0, NaN))   == "1.000"
end
