# Debugging Faults in Software Product Lines with Rule Induction Algorithms

Material of the experiments reported in the following paper submitted to the 
24TH ACM INTERNATIONAL SYSTEMS AND SOFTWARE PRODUCT LINE CONFERENCE (SPLC 2020):

*José Galindo, Ruben Heradio, David Fernandez-Amoros, and David Benavides*. 
**Debugging Faults in Software Product Lines with Rule Induction Algorithms.** 

## JHipster

[JHipster](https://www.jhipster.tech/) is a code generator for web applications 
with 45 selectable features that can produce a total of 26,256 valid configurations.

In:

*Axel Halin, Alexandre Nuttinck, Mathieu Acher, Xavier Devroey, Gilles Perrouin, Benoit Baudry*.
**Test them all, is it worth it? Assessing configuration sampling on the JHipster Web development 
stack**. *Empirical Software Engineering 24(2): 674-717 (2019).*

an exhaustive strategy is adopted to test the JHipster system, checking all its valid configurations.
The test cases, together with their resulting status, are [here](https://github.com/xdevroey/jhipster-dataset).

We have applied three classical rule induction algorithms to explain the detected faults: LEM2, CN2, and AQ. 

Our experimental data is organized in the following directories:
* [original_data](https://github.com/rheradio/spl_fault_debugging/tree/master/jhipster/original_data) includes the CSV file with all tests gathered from [Halin et al.'s repository](https://github.com/xdevroey/jhipster-dataset).
* [script_code](https://github.com/rheradio/spl_fault_debugging/tree/master/jhipster/script_code) includes three scripts written in the R language:
  + [induce_rules.r](https://github.com/rheradio/spl_fault_debugging/blob/master/jhipster/script_code/induce_rules.r) processes the CSV in  [original_data](https://github.com/rheradio/spl_fault_debugging/tree/master/jhipster/original_data) and generates the explaining rules using three alternative algorithms: LEM2, CN2, and AQ. 
  + [crossvalidation.r](https://github.com/rheradio/spl_fault_debugging/blob/master/jhipster/script_code/crossvalidation.R) performs a 10-Fold cross-validation of the algorithms LEM2, CN2, and AQ. Also, the script generates a box-plot that summarizes the results.
  + [plot_rule_statistics.r](https://github.com/rheradio/spl_fault_debugging/blob/master/jhipster/script_code/plot_rule_statistics.R) generates the following plots to summarize the synthesized rules: (i) A histogram and a box-plot analyzing feature interactions, (ii) a cumulative plot relating the rules' coverage achieved with the interactions factor, and (iii) a histogram showing rules' coverage.
* [induced_rules](https://github.com/rheradio/spl_fault_debugging/tree/master/jhipster/induced_rules) includes the generated rules.
* [rule_statistics](https://github.com/rheradio/spl_fault_debugging/tree/master/jhipster/rule_statistics) includes the statistics generated with [crossvalidation.r](https://github.com/rheradio/spl_fault_debugging/blob/master/jhipster/script_code/crossvalidation.R) and [plot_rule_statistics](https://github.com/rheradio/spl_fault_debugging/blob/master/jhipster/script_code/plot_rule_statistics.R).

## Testing Configurable Software Systems: The Failure Observation Challenge

In [SPLC'2020](http://splc2020.net/), Ferreira et al. proposed a [dataset](https://fischerjf.github.io/challenge/) with 22 configurable software systems and an extensive test suite. After checking that LEM2 works better than CN2 and AQ, we applied LEM2 to induce the rules that explain the faults detected in the test suite.

Our experimental data is organized in the following directories:
* [original_data](https://github.com/rheradio/spl_fault_debugging/tree/master/splc2020_challenge/original_data) includes the data in their original format, which is sparsed in several files stored in directories [failuresFound](https://github.com/rheradio/spl_fault_debugging/tree/master/splc2020_challenge/original_data/failuresFound) and [All_valid_conf](https://github.com/rheradio/spl_fault_debugging/tree/master/splc2020_challenge/original_data/workspace_IncLing/Tools/All_valid_conf) 
* [script_code](https://github.com/rheradio/spl_fault_debugging/tree/master/splc2020_challenge/script_code) includes two scripts written in the R language:
  + [format_data.r](https://github.com/rheradio/spl_fault_debugging/blob/master/splc2020_challenge/script_code/format_data.r) formats that original sparsed data into more simple [.csv files](https://github.com/rheradio/spl_fault_debugging/tree/master/splc2020_challenge/formatted_data), one per model in the bechmark.
  + [induce_rules.r](https://github.com/rheradio/spl_fault_debugging/blob/master/splc2020_challenge/script_code/induce_rules.R) induces the rules that explain the faults detected in the test cases.
 * [induced_rules](https://github.com/rheradio/spl_fault_debugging/tree/master/splc2020_challenge/induced_rules) includes the generated rules.
