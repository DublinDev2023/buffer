using System;
using System.Threading.Tasks;
using Confluent.Kafka;
using Confluent.SchemaRegistry;
using Confluent.SchemaRegistry.Serdes;
using dc;

class Program
{
    public static async Task Main(string[] args)
    {
        var schemaRegistryUrl = "http://localhost:8081"; // adjust for your environment
        var bootstrapServers = "localhost:9092";
        var topic = "dc-avro-data";

        var config = new ProducerConfig
        {
            BootstrapServers = bootstrapServers
        };

        var schemaRegistryConfig = new SchemaRegistryConfig
        {
            Url = schemaRegistryUrl
        };

        using var schemaRegistry = new CachedSchemaRegistryClient(schemaRegistryConfig);

        var avroSerializer = new AvroSerializer<DcTelemetry>(schemaRegistry);

        using var producer = new ProducerBuilder<string, DcTelemetry>(config)
            .SetValueSerializer(avroSerializer)
            .Build();

        var dcData = new DcTelemetry
        {
            temperature = 72.5,
            humidity = 40,
            timestamp = DateTime.UtcNow.ToString("o")
        };

        try
        {
            var result = await producer.ProduceAsync(topic, new Message<string, DcTelemetry>
            {
                Key = "dc1",
                Value = dcData
            });

            Console.WriteLine($"Produced to: {result.TopicPartitionOffset}");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error producing message: {ex.Message}");
        }
    }
}

---


using System;
using System.Threading;
using Confluent.Kafka;
using Confluent.SchemaRegistry;
using Confluent.SchemaRegistry.Serdes;
using dc;

class Program
{
    public static void Main(string[] args)
    {
        var bootstrapServers = "localhost:9092";
        var schemaRegistryUrl = "http://localhost:8081";
        var topic = "dc-avro-data";
        var groupId = "dc-consumer-group";

        var consumerConfig = new ConsumerConfig
        {
            BootstrapServers = bootstrapServers,
            GroupId = groupId,
            AutoOffsetReset = AutoOffsetReset.Earliest
        };

        var schemaRegistryConfig = new SchemaRegistryConfig
        {
            Url = schemaRegistryUrl
        };

        using var schemaRegistry = new CachedSchemaRegistryClient(schemaRegistryConfig);

        var avroDeserializer = new AvroDeserializer<DcTelemetry>(schemaRegistry);

        using var consumer = new ConsumerBuilder<string, DcTelemetry>(consumerConfig)
            .SetValueDeserializer(avroDeserializer.AsSyncOverAsync())
            .Build();

        consumer.Subscribe(topic);

        Console.WriteLine("Consuming messages... Press Ctrl+C to exit.");

        var cts = new CancellationTokenSource();

        Console.CancelKeyPress += (_, e) =>
        {
            e.Cancel = true;
            cts.Cancel();
        };

        try
        {
            while (!cts.Token.IsCancellationRequested)
            {
                try
                {
                    var result = consumer.Consume(cts.Token);

                    Console.WriteLine($"Key: {result.Message.Key}");
                    Console.WriteLine($"Temperature: {result.Message.Value.temperature}");
                    Console.WriteLine($"Humidity: {result.Message.Value.humidity}");
                    Console.WriteLine($"Timestamp: {result.Message.Value.timestamp}");
                    Console.WriteLine(new string('-', 40));
                }
                catch (ConsumeException e)
                {
                    Console.WriteLine($"Consume error: {e.Error.Reason}");
                }
            }
        }
        catch (OperationCanceledException)
        {
            Console.WriteLine("Closing consumer...");
            consumer.Close();
        }
    }
}



