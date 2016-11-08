---
title: Expressive Tests with the Builder Pattern
---

I’ve been experimenting with techniques to keep my tests clean and expressive. One that I particularly like is using [builders](https://en.wikipedia.org/wiki/Builder_pattern) to create my system under test eg the object being tested and its dependencies. I’ll describe how I use this technique with an example.

Here are some unit tests for a value object.

```php?start_inline=1
class TrackTest extends \PHPUnit_Framework_TestCase
{
    /**
     * @test
     */
    public function it_can_be_queried_for_its_name()
    {
        $track = Track::fromNameAndDuration(
            "the track's name",
            Duration::fromSeconds(198)
        );

        $this->assertSame("the track's name", $track->getName());
    }

    /**
     * @test
     */
    public function it_can_be_queried_for_its_duration()
    {
        $track = Track::fromNameAndDuration(
            "the track's name",
            Duration::fromSeconds(198)
        );

        $this->assertTrue(
            Duration::fromSeconds(198)->equals($track->getDuration())
        );
    }
}
```

The value represents an audio track. Our tests describe how two query methods on the value should work. The implementations of `Track` and `Duration` can be seen at [this commit](https://github.com/conorsmith/builders-in-tests-example/tree/2569357ceaaff4a3bc4a43749ceaec2b9dc423e2) in the example repo.

Notice that in both tests there is duplication where the value is constructed. Previously I would have been tempted to extract that duplication into a factory method in the test case.

```php?start_inline=1
class TrackTest extends \PHPUnit_Framework_TestCase
{
    /**
     * @test
     */
    public function it_can_be_queried_for_its_name()
    {
        $track = $this->createTrack();

        $this->assertSame("the track's name", $track->getName());
    }

    /**
     * @test
     */
    public function it_can_be_queried_for_its_duration()
    {
        $track = $this->createTrack();

        $this->assertTrue(
            Duration::fromSeconds(198)->equals($track->getDuration())
        );
    }

    private function createTrack(): Track
    {
        return Track::fromNameAndDuration(
            "the track's name",
            Duration::fromSeconds(198)
        );
    }
}
```

Unfortunately this has reduced the expressiveness of the test methods themselves. In the first test we see that the assertion tests that the query returns `"the track's name"`. However we cannot understand the meaning of this literal without examining the implementation of the factory method.

Further issues can arise with the use of a factory method. For instance we may want to test that the `Track` cannot be created when given certain values for its name. We may then need to modify the factory method’s interface and have to modify our existing tests as a consequence.

Instead we can extract our duplicated construction logic into a builder.

```php?start_inline=1
class TrackTest extends \PHPUnit_Framework_TestCase
{
    /**
     * @test
     */
    public function it_can_be_queried_for_its_name()
    {
        $track = $this->track()
            ->withName("the track's name")
            ->build();

        $this->assertSame("the track's name", $track->getName());
    }

    /**
     * @test
     */
    public function it_can_be_queried_for_its_duration()
    {
        $track = $this->track()
            ->withDuration(Duration::fromSeconds(198))
            ->build();

        $this->assertTrue(
            Duration::fromSeconds(198)->equals($track->getDuration())
        );
    }

    private function track()
    {
        return new class()
        {
            /** @var string */
            private $name;

            /** @var Duration */
            private $duration;

            public function __construct()
            {
                $this->name = "some name";
                $this->duration = Duration::fromSeconds(123);
            }

            public function withName(string $name): self
            {
                $this->name = $name;
                return $this;
            }

            public function withDuration(Duration $duration): self
            {
                $this->duration = $duration;
                return $this;
            }

            public function build(): Track
            {
                return Track::fromNameAndDuration(
                    $this->name,
                    $this->duration
                );
            }
        };
    }
}
```

The builder is implemented as an [anonymous class](http://php.net/manual/en/language.oop5.anonymous.php) created in the test case. Its constructor sets default values to be used when the `Track` is built. The `with*()` methods provide a fluent interface for improved readability in the test methods. Importantly our test methods can ignore any constructor parameter that they don’t need to care about. The test for querying the name doesn’t know that a `Track` has a `Duration` and vice-versa.

The builder also hides how exactly the `Track` is built from the test methods, achieving the same deduplication we wanted when considering the factory method. However in the above test case you can see that the `Duration` constructor is still called in three separate locations. We can introduce another builder to solve that.

```php?start_inline=1
class TrackTest extends \PHPUnit_Framework_TestCase
{
    /**
     * @test
     */
    public function it_can_be_queried_for_its_name()
    {
        $track = $this->track()
            ->withName("the track's name")
            ->build();

        $this->assertSame("the track's name", $track->getName());
    }

    /**
     * @test
     */
    public function it_can_be_queried_for_its_duration()
    {
        $track = $this->track()
            ->withDuration($duration = $this->duration()->build())
            ->build();

        $this->assertTrue($duration->equals($track->getDuration()));
    }

    private function track()
    {
        return new class($this->duration()->build())
        {
            /** @var string */
            private $name;

            /** @var Duration */
            private $duration;

            public function __construct(Duration $defaultDuration)
            {
                $this->name = "some name";
                $this->duration = $defaultDuration;
            }

            public function withName(string $name): self
            {
                $this->name = $name;
                return $this;
            }

            public function withDuration(Duration $duration): self
            {
                $this->duration = $duration;
                return $this;
            }

            public function build(): Track
            {
                return Track::fromNameAndDuration(
                    $this->name,
                    $this->duration
                );
            }
        };
    }

    private function duration()
    {
        return new class()
        {
            /** @var int */
            private $seconds;

            public function __construct()
            {
                $this->seconds = 123;
            }

            public function withSeconds(int $seconds): self
            {
                $this->seconds = $seconds;
                return $this;
            }

            public function build(): Duration
            {
                return Duration::fromSeconds($this->seconds);
            }
        };
    }
}
```

The test for querying the `Duration` now uses the builder to create a `Duration` with a default value. The `Track` builder expects a default `Duration` when it is created; the `track()` method passes one in.

In [this commit](https://github.com/conorsmith/builders-in-tests-example/tree/8ab3f7983991947382fe6214a2c9a01828c213fb) of the example repo you’ll see that the builders have been extracted into a trait. This will allow them to be used in other test cases that deal with these same value objects. (I’ll usually extract the builders before it becomes necessary as I like to have my test cases uncluttered for readability.)

Let’s say we need to modify our `Track` values to include an `Artist` that we can query them for. First we’ll need a new test.

```php?start_inline=1
/**
 * @test
 */
public function it_can_be_queried_for_its_artist()
{
    $track = $this->track()
        ->withArtist($artist = $this->artist()->build())
        ->build();

    $this->assertTrue($artist->equals($track->getArtist()));
}
```

We need a new builder for the `Artist` value. We also need to modify the `Track` builder to add a `withArtist()` method and use that value when building.

```php?start_inline=1
private function track()
{
    return new class($this->duration()->build(), $this->artist()->build())
    {
        /** @var string */
        private $name;

        /** @var Duration */
        private $duration;

        /** @var Artist */
        private $artist;

        public function __construct(
            Duration $defaultDuration,
            Artist $defaultArtist
        ) {
            $this->name = "some name";
            $this->duration = $defaultDuration;
            $this->artist = $defaultArtist;
        }

        public function withName(string $name): self
        {
            $this->name = $name;
            return $this;
        }

        public function withDuration(Duration $duration): self
        {
            $this->duration = $duration;
            return $this;
        }

        public function withArtist(Artist $artist): self
        {
            $this->artist = $artist;
            return $this;
        }

        public function build(): Track
        {
            return Track::fromNameAndDurationAndArtist(
                $this->name,
                $this->duration,
                $this->artist
            );
        }
    };
}
```

The modification to the name and signature of the `Track` constructor is hidden from our tests. In fact our original two tests are completely unaltered thanks to the builder. The builder pattern provides us with an inherently extensible interface that minimises the impact of change on our test methods.

A full example repository is available on [GitHub](https://github.com/conorsmith/builders-in-tests-example/commits/master).

**Sidenote**: My implementation of this technique here uses anonymous classes (available in PHP 7) and traits (available in PHP 5.4), but they are not necessary for using the technique. I’ve also used this technique in PHP 5.3 projects with the builders in individual classes.
