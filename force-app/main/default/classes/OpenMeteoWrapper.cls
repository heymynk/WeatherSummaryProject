/**
 * @description       : Wrapper class for OpenMeteo API response
 * @author            : Mayank Singh
 * @last modified on  : 05-14-2024
 * @last modified by  : Mayank Singh
**/
public class OpenMeteoWrapper {
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