Benchmark

Benchmark run from 2026-01-21 11:05:16.121956Z UTC

## System

Benchmark suite executing on the following system:

<table style="width: 1%">
  <tr>
    <th style="width: 1%; white-space: nowrap">Operating System</th>
    <td>macOS</td>
  </tr><tr>
    <th style="white-space: nowrap">CPU Information</th>
    <td style="white-space: nowrap">Apple M4 Max</td>
  </tr><tr>
    <th style="white-space: nowrap">Number of Available Cores</th>
    <td style="white-space: nowrap">16</td>
  </tr><tr>
    <th style="white-space: nowrap">Available Memory</th>
    <td style="white-space: nowrap">128 GB</td>
  </tr><tr>
    <th style="white-space: nowrap">Elixir Version</th>
    <td style="white-space: nowrap">1.19.5</td>
  </tr><tr>
    <th style="white-space: nowrap">Erlang Version</th>
    <td style="white-space: nowrap">28.2</td>
  </tr>
</table>

## Configuration

Benchmark suite executing with the following configuration:

<table style="width: 1%">
  <tr>
    <th style="width: 1%">:time</th>
    <td style="white-space: nowrap">5 s</td>
  </tr><tr>
    <th>:parallel</th>
    <td style="white-space: nowrap">1</td>
  </tr><tr>
    <th>:warmup</th>
    <td style="white-space: nowrap">2 s</td>
  </tr>
</table>

## Statistics



Run Time

<table style="width: 1%">
  <tr>
    <th>Name</th>
    <th style="text-align: right">IPS</th>
    <th style="text-align: right">Average</th>
    <th style="text-align: right">Devitation</th>
    <th style="text-align: right">Median</th>
    <th style="text-align: right">99th&nbsp;%</th>
  </tr>

  <tr>
    <td style="white-space: nowrap">Dictionary.all()</td>
    <td style="white-space: nowrap; text-align: right">504468.26 K</td>
    <td style="white-space: nowrap; text-align: right">0.00198 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;83.16%</td>
    <td style="white-space: nowrap; text-align: right">0.00196 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">0.00275 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">Dictionary.size()</td>
    <td style="white-space: nowrap; text-align: right">268887.31 K</td>
    <td style="white-space: nowrap; text-align: right">0.00372 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;4035.28%</td>
    <td style="white-space: nowrap; text-align: right">0.00420 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">0.00830 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">Dictionary.count_between(4, 8)</td>
    <td style="white-space: nowrap; text-align: right">23793.24 K</td>
    <td style="white-space: nowrap; text-align: right">0.0420 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;1068.95%</td>
    <td style="white-space: nowrap; text-align: right">0.0420 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">0.0830 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">Dictionary.random_word_between(4, 8)</td>
    <td style="white-space: nowrap; text-align: right">5139.03 K</td>
    <td style="white-space: nowrap; text-align: right">0.195 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;2025.78%</td>
    <td style="white-space: nowrap; text-align: right">0.167 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">0.25 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">Token.get_number(2)</td>
    <td style="white-space: nowrap; text-align: right">3529.48 K</td>
    <td style="white-space: nowrap; text-align: right">0.28 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;819.78%</td>
    <td style="white-space: nowrap; text-align: right">0.29 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">0.38 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">Token.get_number(4)</td>
    <td style="white-space: nowrap; text-align: right">3474.90 K</td>
    <td style="white-space: nowrap; text-align: right">0.29 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;950.86%</td>
    <td style="white-space: nowrap; text-align: right">0.29 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">0.42 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">generate(:security)</td>
    <td style="white-space: nowrap; text-align: right">483.78 K</td>
    <td style="white-space: nowrap; text-align: right">2.07 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;261.84%</td>
    <td style="white-space: nowrap; text-align: right">1.96 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">2.96 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">generate(:xkcd)</td>
    <td style="white-space: nowrap; text-align: right">480.83 K</td>
    <td style="white-space: nowrap; text-align: right">2.08 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;245.91%</td>
    <td style="white-space: nowrap; text-align: right">2 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">2.88 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">generate(:web32)</td>
    <td style="white-space: nowrap; text-align: right">344.35 K</td>
    <td style="white-space: nowrap; text-align: right">2.90 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;153.34%</td>
    <td style="white-space: nowrap; text-align: right">2.71 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">4.25 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">generate() default</td>
    <td style="white-space: nowrap; text-align: right">342.80 K</td>
    <td style="white-space: nowrap; text-align: right">2.92 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;165.42%</td>
    <td style="white-space: nowrap; text-align: right">2.75 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">4.17 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">generate(:wifi)</td>
    <td style="white-space: nowrap; text-align: right">303.31 K</td>
    <td style="white-space: nowrap; text-align: right">3.30 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;155.61%</td>
    <td style="white-space: nowrap; text-align: right">3.08 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">5.13 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">transform :upper</td>
    <td style="white-space: nowrap; text-align: right">49.97 K</td>
    <td style="white-space: nowrap; text-align: right">20.01 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;75.10%</td>
    <td style="white-space: nowrap; text-align: right">16.75 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">141.00 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">create() 6 words</td>
    <td style="white-space: nowrap; text-align: right">49.92 K</td>
    <td style="white-space: nowrap; text-align: right">20.03 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;63.45%</td>
    <td style="white-space: nowrap; text-align: right">17.08 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">101.13 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">create() 5 words</td>
    <td style="white-space: nowrap; text-align: right">48.23 K</td>
    <td style="white-space: nowrap; text-align: right">20.73 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;73.71%</td>
    <td style="white-space: nowrap; text-align: right">17.29 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">72.25 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">create() 3 words</td>
    <td style="white-space: nowrap; text-align: right">47.27 K</td>
    <td style="white-space: nowrap; text-align: right">21.15 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;63.48%</td>
    <td style="white-space: nowrap; text-align: right">17.58 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">82.96 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">transform :capitalize</td>
    <td style="white-space: nowrap; text-align: right">46.72 K</td>
    <td style="white-space: nowrap; text-align: right">21.40 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;64.61%</td>
    <td style="white-space: nowrap; text-align: right">17.83 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">87.50 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">transform :alternate</td>
    <td style="white-space: nowrap; text-align: right">46.42 K</td>
    <td style="white-space: nowrap; text-align: right">21.54 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;65.67%</td>
    <td style="white-space: nowrap; text-align: right">17.88 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">109.65 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">create() 4 words</td>
    <td style="white-space: nowrap; text-align: right">46.28 K</td>
    <td style="white-space: nowrap; text-align: right">21.61 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;69.21%</td>
    <td style="white-space: nowrap; text-align: right">18.33 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">79.75 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">transform :lower</td>
    <td style="white-space: nowrap; text-align: right">46.10 K</td>
    <td style="white-space: nowrap; text-align: right">21.69 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;67.20%</td>
    <td style="white-space: nowrap; text-align: right">18.17 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">139.96 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">transform :random</td>
    <td style="white-space: nowrap; text-align: right">45.63 K</td>
    <td style="white-space: nowrap; text-align: right">21.92 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;61.70%</td>
    <td style="white-space: nowrap; text-align: right">18.42 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">83.29 &micro;s</td>
  </tr>

</table>


Run Time Comparison

<table style="width: 1%">
  <tr>
    <th>Name</th>
    <th style="text-align: right">IPS</th>
    <th style="text-align: right">Slower</th>
  <tr>
    <td style="white-space: nowrap">Dictionary.all()</td>
    <td style="white-space: nowrap;text-align: right">504468.26 K</td>
    <td>&nbsp;</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">Dictionary.size()</td>
    <td style="white-space: nowrap; text-align: right">268887.31 K</td>
    <td style="white-space: nowrap; text-align: right">1.88x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">Dictionary.count_between(4, 8)</td>
    <td style="white-space: nowrap; text-align: right">23793.24 K</td>
    <td style="white-space: nowrap; text-align: right">21.2x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">Dictionary.random_word_between(4, 8)</td>
    <td style="white-space: nowrap; text-align: right">5139.03 K</td>
    <td style="white-space: nowrap; text-align: right">98.16x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">Token.get_number(2)</td>
    <td style="white-space: nowrap; text-align: right">3529.48 K</td>
    <td style="white-space: nowrap; text-align: right">142.93x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">Token.get_number(4)</td>
    <td style="white-space: nowrap; text-align: right">3474.90 K</td>
    <td style="white-space: nowrap; text-align: right">145.17x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">generate(:security)</td>
    <td style="white-space: nowrap; text-align: right">483.78 K</td>
    <td style="white-space: nowrap; text-align: right">1042.77x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">generate(:xkcd)</td>
    <td style="white-space: nowrap; text-align: right">480.83 K</td>
    <td style="white-space: nowrap; text-align: right">1049.16x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">generate(:web32)</td>
    <td style="white-space: nowrap; text-align: right">344.35 K</td>
    <td style="white-space: nowrap; text-align: right">1464.98x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">generate() default</td>
    <td style="white-space: nowrap; text-align: right">342.80 K</td>
    <td style="white-space: nowrap; text-align: right">1471.62x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">generate(:wifi)</td>
    <td style="white-space: nowrap; text-align: right">303.31 K</td>
    <td style="white-space: nowrap; text-align: right">1663.2x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">transform :upper</td>
    <td style="white-space: nowrap; text-align: right">49.97 K</td>
    <td style="white-space: nowrap; text-align: right">10095.85x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">create() 6 words</td>
    <td style="white-space: nowrap; text-align: right">49.92 K</td>
    <td style="white-space: nowrap; text-align: right">10105.27x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">create() 5 words</td>
    <td style="white-space: nowrap; text-align: right">48.23 K</td>
    <td style="white-space: nowrap; text-align: right">10458.99x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">create() 3 words</td>
    <td style="white-space: nowrap; text-align: right">47.27 K</td>
    <td style="white-space: nowrap; text-align: right">10671.0x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">transform :capitalize</td>
    <td style="white-space: nowrap; text-align: right">46.72 K</td>
    <td style="white-space: nowrap; text-align: right">10797.86x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">transform :alternate</td>
    <td style="white-space: nowrap; text-align: right">46.42 K</td>
    <td style="white-space: nowrap; text-align: right">10866.45x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">create() 4 words</td>
    <td style="white-space: nowrap; text-align: right">46.28 K</td>
    <td style="white-space: nowrap; text-align: right">10900.3x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">transform :lower</td>
    <td style="white-space: nowrap; text-align: right">46.10 K</td>
    <td style="white-space: nowrap; text-align: right">10942.38x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">transform :random</td>
    <td style="white-space: nowrap; text-align: right">45.63 K</td>
    <td style="white-space: nowrap; text-align: right">11056.07x</td>
  </tr>

</table>



Memory Usage

<table style="width: 1%">
  <tr>
    <th>Name</th>
    <th style="text-align: right">Average</th>
    <th style="text-align: right">Factor</th>
  </tr>
  <tr>
    <td style="white-space: nowrap">Dictionary.all()</td>
    <td style="white-space: nowrap">0 KB</td>
    <td>&nbsp;</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">Dictionary.size()</td>
    <td style="white-space: nowrap">0 KB</td>
    <td>1.0x</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">Dictionary.count_between(4, 8)</td>
    <td style="white-space: nowrap">0.0234 KB</td>
    <td>&mdash;</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">Dictionary.random_word_between(4, 8)</td>
    <td style="white-space: nowrap">0.0469 KB</td>
    <td>&mdash;</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">Token.get_number(2)</td>
    <td style="white-space: nowrap">0.61 KB</td>
    <td>&mdash;</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">Token.get_number(4)</td>
    <td style="white-space: nowrap">0.62 KB</td>
    <td>&mdash;</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">generate(:security)</td>
    <td style="white-space: nowrap">2.19 KB</td>
    <td>&mdash;</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">generate(:xkcd)</td>
    <td style="white-space: nowrap">1.13 KB</td>
    <td>&mdash;</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">generate(:web32)</td>
    <td style="white-space: nowrap">5.72 KB</td>
    <td>&mdash;</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">generate() default</td>
    <td style="white-space: nowrap">7.56 KB</td>
    <td>&mdash;</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">generate(:wifi)</td>
    <td style="white-space: nowrap">6.60 KB</td>
    <td>&mdash;</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">transform :upper</td>
    <td style="white-space: nowrap">17.73 KB</td>
    <td>&mdash;</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">create() 6 words</td>
    <td style="white-space: nowrap">18.12 KB</td>
    <td>&mdash;</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">create() 5 words</td>
    <td style="white-space: nowrap">17.98 KB</td>
    <td>&mdash;</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">create() 3 words</td>
    <td style="white-space: nowrap">17.80 KB</td>
    <td>&mdash;</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">transform :capitalize</td>
    <td style="white-space: nowrap">17.73 KB</td>
    <td>&mdash;</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">transform :alternate</td>
    <td style="white-space: nowrap">17.80 KB</td>
    <td>&mdash;</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">create() 4 words</td>
    <td style="white-space: nowrap">17.85 KB</td>
    <td>&mdash;</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">transform :lower</td>
    <td style="white-space: nowrap">17.73 KB</td>
    <td>&mdash;</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">transform :random</td>
    <td style="white-space: nowrap">17.79 KB</td>
    <td>&mdash;</td>
  </tr>
</table>