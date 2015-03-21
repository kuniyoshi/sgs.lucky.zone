sgs.lucky.zone
==============

MISSION STATEMENT
-----------------

Predict the score, and ranking in the Lucky Zone.

VERSION
-------

0.01

CHANGES
-------

- 0.01 Sat Mar 21 15:27:33 JST 2015
  - first version

SYNOPSIS
--------

### INPUT NEW DATA

Square bracket[] shows the typed from keyborad.

```
  $ bin/append_training_term_data.pl score_data_filename
  border of 1 - 800 : [100]
  border of 801 - 1500 : [80]
  ...
  [w]
  [q]
```

### PREDICT

```
  $ R
  > library(devtools)
  > devtools::load_all()
  > usage.predict("2015-03-19T22:00:00",
                  "2015-03-19T23:55:00",
                  target_datetime = "2015-03-20T00:00:00")
  > usage.game(7473, 7565)
```

DESCRIPTION
-----------

This repository predicts how much score needs,
when someone want to ranking in the Lucky Zone.

The Lucky Zone is a range that given bonus
is better than the around ranking.  For example,
when the Lucky Zone is ranged between 100[score],
and 200[score], 150[score] given 100[bonus], but
250[score] given 50[bonus], and 50[score] given
40[bonus].  Lucky Zone can be given good bonus
in exchange hard to be aimed.  This repository
aims what score may be in the Lucky Zone.

One more important thing exists.  The score is
only valid in the term called Training Term.
And Lucky Zone fixes at the end of Training Term.

Note that Lucky Zone may appear only at the
end of Training Term, but in this repository,
Lucky Zone means the ranking range at the time.

To be ranged Lucky Zone needs to predict how much
score is ranged at the end of Training Term.

To predict the Lucky Score which is in the Lucky Zone,
it requires sample data.  Sample data should be inputted
fast.  Lucky Zone is moving while Training Term,
and accuracy of prediction depends on how much sample
data given.  Thus fast sample data inputting can increase
accuracy of prediction.

Increasing sample data will be described below section.

When the Lucky Score is predicted, make your score
the Lucky Score.

The score will increase with discrete value.
In my case, most increasable values are:

- 18
- 19
- 20
- 21
- 33
- 34.

Then, calculate what combination makes the score to be
Lucky Score is this repository task.

Listing combination will be described below section.

### INPUT SAMPLE DATA

Most important thing when inputting sample data is
start script at the time new ranking is published.

The datetime of the sample data effects accuracy
of prediction.  The ranking is published about
every 10 minutes with no datetime value.  So,
We estimate the ranking datetime from published
datetime.  To increase accuracy of prediction,
check the ranking frequently, and start script
when it is updated.  Starting script saves keeps
datetime at the started time.  After started the
script, input speed is not important because
it has been saved at the started time.

The script `bin/append_training_term_data.pl`
collects one sample data per execution.  The script
needs filename argument to know where to append
the new sample data.

The script has two main modes.  First mode is
insert mode which inputs ranking scores.  The
second mode is normal mode which controls the
script.

To switch these two modes, type `ESC` to change
from insert mode to normal mode, and type `e` to
change from normal mode to insert mode.

The command help can be shown typing `h` at the
normal mode.

### PREDICT LUCKY SCORE

After collect sample data, the Lucky Score
can be predicted by linear regression model.

To predict the fixed Lucky Zone, run below.

``` R
  $ R
  > library(devtools)
  > devtools::load_all()
  > usage.predict("2015-03-19T22:00:00",
                  "2015-03-19T23:55:00",
                  target_datetime = "2015-03-20T00:00:00")
```

### LIST COMBINATION SCORES TO BE LUCKY SCORE

After predict the score, run below to how can
achive the score in the Training Term.

``` R
  $ R
  > library(devtools)
  > devtools::load_all()
  > usage.game(7473, 7565)
```

### STATISTICS

TODO:

TODO
----

This repository is used at 2015-02 Training Term.
Thus there is no Corporation Battle.  Support
Corporation Battle.

Improve statistics.

Improve scripts.

DEPENDENCY
----------

- perl
  - Term::ReadKey
  - Time::Piece
- R
  - devtools
  - xts
  - ggplot2
  - lattice

EXTERNAL LINKS
--------------

- [SCHOOL GIRL STRICKERS](http://schoolgirlstrikers.jp/) (c) 2014,2015 SQUARE ENIX CO., LTD. All Rights Reserved.

LICENSE
-------

Artistic-2.0
