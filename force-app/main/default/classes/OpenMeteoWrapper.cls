public with sharing class OpenMeteoWrapper {
      public Hourly hourly;

    public class Hourly {
        public List<String> timestamps; 
        public List<Double> temperature_2m; 
        public List<Integer> relative_humidity_2m; 
        public List<Double> rain; 
        public List<Double> showers; 
        public List<Double> snowfall; 
    }        
}
